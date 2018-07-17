defmodule CadetWeb.ViewHelpers do
  @moduledoc """
  Helper functions shared throughout views
  """

  def format_datetime(datetime) do
    Timex.format!(DateTime.truncate(datetime, :millisecond), "{ISO:Extended}")
  end

  @doc """
  This function allows you to build a map for a view from a map of transformations or a list of fields.

  Given a `key_list`, it is the equivalent of `Map.take(source, key_list)`.

  Given a map of `%{view_field: source_field, ...}`, it is the equivalent of `%{view_field: Map.get(source, source_field), ...}`

  Given a map of `%{view_field: source_function, ...}`, it is the equivalent of `%{view_field: apply(source_function, source)}`

  Examples:
  ```
  source = %{
    foofoo: "ho",
    barbar: "ha",
    foobar: "hoha"
  }

  field_list = [:foofoo, :barbar]

  transform_map_for_view(source, field_list)
  > %{
    foofoo: "ho",
    barbar: "bar"
  }

  key_transformations = %{
    foo: :foofoo,
    bar: :barbar
  }

  transform_map_for_view(source, key_transformations)
  > %{
    foo: Map.get(source, :foofoo),
    bar: Map.get(source, :barbar)
  }

  function_transformations = %{
    foo: fn source -> source.foofoo <> "hoho",
    bar: fn source -> source.barbar <> "barbar"
  }

  transform_map_for_view(source, function_transformations)
  > %{
    foo: source.foofoo <> "hoho",
    bar: source.barbar <> "barbar"
  }
  ```
  """
  def transform_map_for_view(source, transformations) when is_map(transformations) do
    Enum.reduce(
      transformations,
      %{},
      fn {field_name, transformation}, acc ->
        Map.put(acc, field_name, get_value(transformation, source))
      end
    )
  end

  def transform_map_for_view(source, fields) when is_list(fields) do
    transform_map_for_view(
      source,
      Enum.reduce(fields, %{}, fn field, acc -> Map.put(acc, field, field) end)
    )
  end

  defp get_value(source_spec, value_store) when is_function(source_spec) do
    Kernel.apply(source_spec, [value_store])
  end

  defp get_value(source_spec, value_store) when is_binary(source_spec) or is_atom(source_spec) do
    Map.get(value_store, source_spec)
  end
end
