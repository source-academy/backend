defmodule Cadet.Test.XMLGenerator do
  @moduledoc """
  This module contains functions to produce sample XML codes in accordance to
  the specification (xml_api.rst).
  """

  alias Cadet.Assessments.Assessment

  import XmlBuilder
  import Cadet.Factory

  def generate_xml_for(assessment = %Assessment{}, questions) do
    generate(
      content([
        task(
          map_convert_keys(assessment, %{
            kind: :type,
            number: :number,
            startdate: :open_at,
            duedate: :close_at,
            title: :title,
            story: :story
          }),
          nil
        )
      ])
    )
  end

  defp content(children) do
    document(
      {"CONTENT",
       %{
         "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
         "xmlns:xlink" => "http://128.199.210.247"
       }, children}
    )
  end

  defp task(raw_attrs, children) do
    {"TASK", map_permit_keys(raw_attrs, ~w(kind number startdate duedate title story)a), children}
  end

  defp map_permit_keys(map, keys) when is_map(map) and is_list(keys) do
    Enum.filter(map, fn {k, v} -> k in keys and not is_nil(v) end)
  end

  defp map_convert_keys(struct, mapping) do
    map = Map.from_struct(struct)

    map
    |> Enum.filter(fn {k, v} -> k in mapping end)
    |> Enum.map(fn
      {k, v} when is_atom(v) -> {k, map[v]}
      _ -> nil
    end)
    |> Enum.filter(&(not is_nil(&1)))
    |> Enum.into(%{})
  end
end
