defmodule CadetWeb.AssessmentsHelpers do
  @moduledoc """
  Helper functions for Assessments and Grading
  """
  import CadetWeb.ViewHelper

  defp build_library(%{library: library}) do
    transform_map_for_view(library, %{
      chapter: :chapter,
      globals: :globals,
      external: &build_external_library(%{external_library: &1.external})
    })
  end

  defp build_external_library(%{external_library: external_library}) do
    transform_map_for_view(external_library, [:name, :symbols])
  end

  def build_question_by_assessment_config(
        %{
          question: question,
          assessment_config: assessment_config
        },
        all_testcases? \\ false
      ) do
    Map.merge(
      build_generic_question_fields(%{question: question}),
      build_question_content_by_config(
        %{
          question: question,
          assessment_config: assessment_config
        },
        all_testcases?
      )
    )
  end

  def build_question_with_answer_and_solution_if_ungraded(%{
        question: question,
        assessment: assessment
      }) do
    components = [
      build_question_by_assessment_config(%{
        question: question,
        assessment_config: assessment.config
      }),
      build_answer_fields_by_question_type(%{question: question}),
      build_solution_if_ungraded_by_config(%{question: question, assessment: assessment})
    ]

    components
    |> Enum.filter(& &1)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp build_generic_question_fields(%{question: question}) do
    transform_map_for_view(question, %{
      id: :id,
      type: :type,
      library: &build_library(%{library: &1.library}),
      maxXp: :max_xp
    })
  end

  defp build_solution_if_ungraded_by_config(%{
         question: %{question: question, type: question_type},
         assessment: %{config: assessment_config}
       }) do
    if !assessment_config.is_graded do
      solution_getter =
        case question_type do
          :programming -> &Map.get(&1, "solution")
          :mcq -> &find_correct_choice(&1["choices"])
          :voting -> nil
        end

      transform_map_for_view(question, %{solution: solution_getter})
    end
  end

  defp answer_builder_for(:programming), do: & &1.answer["code"]
  defp answer_builder_for(:mcq), do: & &1.answer["choice_id"]
  defp answer_builder_for(:voting), do: nil

  defp build_answer_fields_by_question_type(%{
         question: %{answer: answer, type: question_type}
       }) do
    # No need to check if answer exists since empty answer would be a
    # `%Answer{..., answer: nil}` and nil["anything"] = nil

    %{grader: grader} = answer

    transform_map_for_view(answer, %{
      answer: answer_builder_for(question_type),
      grader: grader_builder(grader),
      gradedAt: graded_at_builder(grader),
      xp: &((&1.xp || 0) + (&1.xp_adjustment || 0)),
      autogradingStatus: :autograding_status,
      autogradingResults: build_results(%{results: answer.autograding_results}),
      comments: :comments
    })
  end

  defp build_results(%{results: results}) do
    case results do
      nil -> nil
      _ -> &Enum.map(&1.autograding_results, fn result -> build_result(result) end)
    end
  end

  def build_result(result) do
    transform_map_for_view(result, %{
      resultType: "resultType",
      expected: "expected",
      actual: "actual",
      errorType: "errorType",
      errors: build_errors(result["errors"])
    })
  end

  defp build_errors(errors) do
    case errors do
      nil -> nil
      _ -> &Enum.map(&1["errors"], fn error -> build_error(error) end)
    end
  end

  defp build_error(error) do
    transform_map_for_view(error, %{
      errorType: "errorType",
      line: "line",
      location: "location",
      errorLine: "errorLine",
      errorExplanation: "errorExplanation"
    })
  end

  defp build_contest_entry(entry) do
    transform_map_for_view(entry, %{
      submission_id: :submission_id,
      answer: :answer,
      rank: :rank
    })
  end

  defp build_contest_leaderboard_entry(leaderboard_ans) do
    Map.put(
      transform_map_for_view(leaderboard_ans, %{
        submission_id: :submission_id,
        answer: :answer,
        student_name: :student_name
      }),
      "score",
      Float.round(leaderboard_ans.relative_score, 2)
    )
  end

  defp build_choice(choice) do
    transform_map_for_view(choice, %{
      id: "choice_id",
      content: "content",
      hint: "hint"
    })
  end

  defp build_testcase(testcase, type) do
    transform_map_for_view(testcase, %{
      answer: "answer",
      score: "score",
      program: "program",
      # Create a 1-arity function to return the type of the testcase as a string
      type: fn _ -> type end
    })
  end

  defp build_testcases(%{assessment_config: assessment_config}, all_testcases?) do
    cond do
      all_testcases? ->
        &Enum.concat(
          Enum.map(&1["public"], fn testcase -> build_testcase(testcase, "public") end),
          Enum.map(&1["private"], fn testcase -> build_testcase(testcase, "private") end)
        )

      # build hidden testcases if ungraded
      !assessment_config.is_graded ->
        &Enum.concat(
          Enum.map(&1["public"], fn testcase -> build_testcase(testcase, "public") end),
          Enum.map(&1["private"], fn testcase -> build_testcase(testcase, "hidden") end)
        )

      true ->
        &Enum.map(&1["public"], fn testcase -> build_testcase(testcase, "public") end)
    end
  end

  defp build_postpend(%{assessment_config: assessment_config}, all_testcases?) do
    case {all_testcases?, assessment_config.is_graded} do
      {true, _} -> & &1["postpend"]
      {_, false} -> & &1["postpend"]
      # Create a 1-arity function to return an empty postpend for non-paths
      _ -> fn _question -> "" end
    end
  end

  defp build_question_content_by_config(
         %{
           question: %{question: question, type: question_type},
           assessment_config: assessment_config
         },
         all_testcases?
       ) do
    case question_type do
      :programming ->
        transform_map_for_view(question, %{
          content: "content",
          prepend: "prepend",
          solutionTemplate: "template",
          postpend: build_postpend(%{assessment_config: assessment_config}, all_testcases?),
          testcases: build_testcases(%{assessment_config: assessment_config}, all_testcases?)
        })

      :mcq ->
        transform_map_for_view(question, %{
          content: "content",
          choices: &Enum.map(&1["choices"], fn choice -> build_choice(choice) end)
        })

      :voting ->
        transform_map_for_view(question, %{
          content: "content",
          prepend: "prepend",
          solutionTemplate: "template",
          contestEntries:
            &Enum.map(&1[:contest_entries], fn entry -> build_contest_entry(entry) end),
          contestLeaderboard:
            &Enum.map(&1[:contest_leaderboard], fn entry ->
              build_contest_leaderboard_entry(entry)
            end)
        })
    end
  end

  defp find_correct_choice(choices) do
    choices
    |> Enum.find(&Map.get(&1, "is_correct"))
    |> Map.get("choice_id")
  end
end
