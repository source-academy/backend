defmodule Cadet.Test.XMLGenerator do
  @moduledoc """
  This module contains functions to produce sample XML codes in accordance to
  the specification (xml_api.rst).

  # TODO: Refactor using macros
  """

  alias Cadet.Assessments.{Assessment, Question}

  import XmlBuilder

  # TODO: refactor in smaller functions
  @spec generate_xml_for(Assessment.t(), [Question.t()], [{atom(), any()}]) :: String.t()
  def generate_xml_for(
        assessment = %Assessment{},
        questions,
        opts \\ []
      ) do
    assessment_wide_library =
      if opts[:library] do
        process_library(opts[:library],
          using: &programminglanguage/2,
          no_deployment: opts[:no_programminglanguage]
        )
      else
        []
      end

    assessment_wide_grading_library =
      if opts[:grading_library] do
        process_library(
          opts[:grading_library],
          using: &graderprogramminglanguage/2,
          no_deployment: opts[:no_programminglanguage]
        )
      else
        []
      end

    generate(
      content([
        task(
          map_convert_keys(assessment, %{
            access: :access,
            number: :number,
            open_at: :startdate,
            close_at: :duedate,
            title: :title,
            story: :story
          }),
          [
            password(assessment.password),
            reading(assessment.reading),
            websummary(assessment.summary_short),
            text(assessment.summary_long),
            problems([
              for question <- questions do
                problem(
                  generate_problem_attrs(
                    question,
                    opts[:problem_permit_keys],
                    opts[:override_type]
                  ),
                  [text(question.question.content)] ++
                    process_question_by_question_type(question) ++
                    process_library(
                      question.library,
                      using: &programminglanguage/2,
                      no_deployment: opts[:no_programminglanguage]
                    ) ++
                    process_library(
                      question.grading_library,
                      using: &graderprogramminglanguage/2,
                      no_deployment: opts[:no_programminglanguage]
                    )
                )
              end
            ])
          ] ++ assessment_wide_library ++ assessment_wide_grading_library
        )
      ])
    )
  end

  defp generate_problem_attrs(question, permit_keys, override_type) do
    type = override_type || question.type

    map_permit_keys(
      %{type: type, maxxp: question.max_xp},
      permit_keys || ~w(type maxxp)a
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
          choice(%{correct: mcq_choice.is_correct, hint: mcq_choice.hint}, [
            text(mcq_choice.content)
          ])
        end

      :programming ->
        prepend_field = [prepend(question.question.prepend)]

        template_field = [template(question.question.template)]

        postpend_field = [postpend(question.question.postpend)]

        solution_field =
          if question.question[:solution] do
            [solution(question.question[:solution])]
          else
            []
          end

        testcases_fields = [
          testcases(
            [
              for testcase <- question.question[:public] do
                public(%{score: testcase.score, answer: testcase.answer}, testcase.program)
              end
            ] ++
              [
                for testcase <- question.question[:opaque] do
                  opaque(%{score: testcase.score, answer: testcase.answer}, testcase.program)
                end
              ] ++
              [
                for testcase <- question.question[:secret] do
                  secret(%{score: testcase.score, answer: testcase.answer}, testcase.program)
                end
              ]
          )
        ]

        [
          snippet(
            prepend_field ++
              template_field ++ postpend_field ++ solution_field ++ testcases_fields
          )
        ]

      :voting ->
        prepend_field = [prepend(question.question.prepend)]

        template_field = [template(question.question.template)]

        voting_field =
          voting(%{
            reveal_hours: question.question.reveal_hours,
            assessment_number: question.question.contest_number,
            token_divider: question.question.token_divider
          })

        [
          snippet(prepend_field ++ template_field)
        ] ++ [voting_field]
    end
  end

  defp voting(raw_attr) do
    {"VOTING", map_permit_keys(raw_attr, ~w(assessment_number reveal_hours token_divider)a)}
  end

  defp programminglanguage(raw_attrs, children) do
    {"PROGRAMMINGLANGUAGE", map_permit_keys(raw_attrs, ~w(interpreter)a), children}
  end

  defp graderprogramminglanguage(raw_attrs, children) do
    {"GRADERPROGRAMMINGLANGUAGE", map_permit_keys(raw_attrs, ~w(interpreter)a), children}
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

  defp process_library(library, using: tag_function, no_deployment: no_deployment)
       when is_map(library) do
    if no_deployment do
      []
    else
      [
        tag_function.(
          %{interpreter: library.chapter},
          [
            external(
              %{name: library.external.name},
              Enum.map(library.external.symbols, &symbol/1)
            )
          ] ++ process_globals(library[:globals])
        )
      ]
    end
  end

  defp process_globals(nil) do
    []
  end

  defp process_globals(globals) when is_map(globals) do
    for {k, v} <- globals do
      global([identifier(k), value(v)])
    end
  end

  defp task(raw_attrs, children) do
    {"TASK", map_permit_keys(raw_attrs, ~w(number startdate duedate title story access)a),
     children}
  end

  defp password(content) do
    {"PASSWORD", nil, content}
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
    {"PROBLEM", map_permit_keys(raw_attrs, ~w(maxxp type)a), children}
  end

  defp text(content) do
    {"TEXT", nil, content}
  end

  defp choice(raw_attrs, content) do
    {"CHOICE", map_permit_keys(raw_attrs, ~w(correct hint)a), content}
  end

  defp snippet(children) do
    {"SNIPPET", nil, children}
  end

  defp prepend(content) do
    {"PREPEND", nil, content}
  end

  defp template(content) do
    {"TEMPLATE", nil, content}
  end

  defp postpend(content) do
    {"POSTPEND", nil, content}
  end

  defp solution(content) do
    {"SOLUTION", nil, content}
  end

  defp testcases(children) do
    {"TESTCASES", nil, children}
  end

  defp public(raw_attrs, content) do
    {"PUBLIC", map_permit_keys(raw_attrs, ~w(score answer)a), content}
  end

  defp opaque(raw_attrs, content) do
    {"OPAQUE", map_permit_keys(raw_attrs, ~w(score answer)a), content}
  end

  defp secret(raw_attrs, content) do
    {"SECRET", map_permit_keys(raw_attrs, ~w(score answer)a), content}
  end

  defp map_permit_keys(map, keys) when is_map(map) and is_list(keys) do
    map
    |> Enum.filter(fn {k, v} -> k in keys and not is_nil(v) end)
    |> Enum.into(%{})
  end

  defp map_convert_keys(struct, mapping) do
    struct
    |> Map.from_struct()
    |> Enum.filter(fn {k, v} -> k in Map.keys(mapping) and not is_nil(v) end)
    |> Enum.into(%{}, fn {k, v} -> {mapping[k], v} end)
  end
end
