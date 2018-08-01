defmodule Cadet.Test.XMLGenerator do
  @moduledoc """
  This module contains functions to produce sample XML codes in accordance to
  the specification (xml_api.rst).
  """

  alias Cadet.Assessments.{Assessment, Question}

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
          [
            problems([
              for question <- questions do
                problem(
                  %{type: question.type, maxgrade: question.max_grade},
                  [text(question.question.content)] ++ process_question_by_question_type(question)
                )
              end
            ])
          ]
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

  defp process_question_by_question_type(question = %Question{}) do
    case question.type do
      :mcq ->
        for mcq_choice <- question.question.choices do
          choice(%{correct: mcq_choice.is_correct}, mcq_choice.content)
        end

      :programming ->
        # TODO: implement this
        []
    end
  end

  defp task(raw_attrs, children) do
    {"TASK", map_permit_keys(raw_attrs, ~w(kind number startdate duedate title story)a), children}
  end

  defp problems(children) do
    {"PROBLEMS", %{}, children}
  end

  defp problem(raw_attrs, children) do
    {"PROBLEM", map_permit_keys(raw_attrs, ~w(maxgrade type)a), children}
  end

  defp text(content) do
    {"TEXT", %{}, content}
  end

  defp choice(raw_attrs, content) do
    {"CHOICE", map_permit_keys(raw_attrs, ~w(correct)a), content}
  end

  defp snippet(children) do
    {"SNIPPET", %{}, children}
  end

  defp template(content) do
    {"TEMPLATE", %{}, content}
  end

  defp solution(content) do
    {"SOLUTION", %{}, content}
  end

  defp grader(content) do
    {"GRADER", %{}, content}
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
