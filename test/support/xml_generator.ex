defmodule Cadet.Test.XMLGenerator do
  @moduledoc """
  This module contains functions to produce sample XML codes in accordance to
  the specification (xml_api.rst).

  # TODO: Refactor using macros
  """

  alias Cadet.Assessments.{Assessment, Question}

  import XmlBuilder

  @spec generate_xml_for(%Assessment{}, [%Question{}], map() | nil, map() | nil) :: String.t()
  def generate_xml_for(
        assessment = %Assessment{},
        questions,
        library \\ nil,
        grading_library \\ nil
      ) do
    assessment_wide_library =
      if library do
        process_library(library, using: &deployment/2)
      else
        []
      end

    assessment_wide_grading_library =
      if grading_library do
        process_library(grading_library, using: &graderdeployment/2)
      else
        []
      end

    generate(
      content([
        task(
          map_convert_keys(assessment, %{
            type: :kind,
            number: :number,
            open_at: :startdate,
            close_at: :duedate,
            title: :title,
            story: :story
          }),
          [
            reading(assessment.reading),
            websummary(assessment.summary_short),
            text(assessment.summary_long),
            problems([
              for question <- questions do
                problem(
                  %{type: question.type, maxgrade: question.max_grade},
                  [text(question.question.content)] ++
                    process_question_by_question_type(question) ++
                    process_library(question.library, using: &deployment/2) ++
                    process_library(question.grading_library, using: &graderdeployment/2)
                )
              end
            ])
          ] ++ assessment_wide_library ++ assessment_wide_grading_library
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
        template_field = [template(question.question.solution_template)]

        solution_field =
          if question.question[:solution] do
            [solution(question.question[:solution])]
          else
            []
          end

        grader_fields =
          if question.question[:autograder] do
            Enum.map(question.question[:autograder], &grader/1)
          else
            []
          end

        [snippet(template_field ++ solution_field ++ grader_fields)]
    end
  end

  defp deployment(raw_attrs, children) do
    {"DEPLOYMENT", map_permit_keys(raw_attrs, ~w(interpreter)a), children}
  end

  defp graderdeployment(raw_attrs, children) do
    {"GRADERDEPLOYMENT", map_permit_keys(raw_attrs, ~w(interpreter)a), children}
  end

  defp external(raw_attrs, children) do
    {"EXTERNAL", map_permit_keys(raw_attrs, ~w(name)a), children}
  end

  defp symbol(content) do
    {"SYMBOL", nil, content}
  end

  defp global(children) do
    {"GLOBAL", nil, children}
  end

  defp identifier(content) do
    {"IDENTIFIER", nil, content}
  end

  defp value(content) do
    {"VALUE", nil, content}
  end

  defp process_library(nil, _) do
    []
  end

  defp process_library(library, using: tag_function) when is_map(library) do
    [
      tag_function.(
        %{interpreter: library.chapter},
        [external(%{name: library.external.name}, Enum.map(library.external.symbols, &symbol/1))] ++
          process_globals(library[:globals])
      )
    ]
  end

  defp process_globals(globals) when is_nil(globals) do
    []
  end

  defp process_globals(globals) when is_map(globals) do
    for {k, v} <- globals do
      global([identifier(k), value(v)])
    end
  end

  defp task(raw_attrs, children) do
    {"TASK", map_permit_keys(raw_attrs, ~w(kind number startdate duedate title story)a), children}
  end

  defp reading(content) do
    {"READING", nil, content}
  end

  defp websummary(content) do
    {"WEBSUMMARY", nil, content}
  end

  defp problems(children) do
    {"PROBLEMS", nil, children}
  end

  defp problem(raw_attrs, children) do
    {"PROBLEM", map_permit_keys(raw_attrs, ~w(maxgrade type)a), children}
  end

  defp text(content) do
    {"TEXT", nil, content}
  end

  defp choice(raw_attrs, content) do
    {"CHOICE", map_permit_keys(raw_attrs, ~w(correct)a), content}
  end

  defp snippet(children) do
    {"SNIPPET", nil, children}
  end

  defp template(content) do
    {"TEMPLATE", nil, content}
  end

  defp solution(content) do
    {"SOLUTION", nil, content}
  end

  defp grader(content) do
    {"GRADER", nil, content}
  end

  defp map_permit_keys(map, keys) when is_map(map) and is_list(keys) do
    Enum.filter(map, fn {k, v} -> k in keys and not is_nil(v) end)
  end

  defp map_convert_keys(struct, mapping) do
    map = Map.from_struct(struct)

    map
    |> Enum.filter(fn {k, v} -> k in Map.keys(mapping) and not is_nil(v) end)
    |> Enum.into(%{}, fn {k, v} -> {mapping[k], v} end)
  end
end
