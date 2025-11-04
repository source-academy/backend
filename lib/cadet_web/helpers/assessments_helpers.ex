defmodule CadetWeb.AssessmentsHelpers do
  @moduledoc """
  Helper functions for Assessments and Grading
  """
  import CadetWeb.ViewHelper

  defp build_library(%{library: library}) do
    transform_map_for_view(library, %{
      chapter: :chapter,
      variant: :variant,
      execTimeMs: :exec_time_ms,
      globals: :globals,
      external: &build_external_library(%{external_library: &1.external}),
      languageOptions: :language_options
    })
  end

  defp build_external_library(%{external_library: external_library}) do
    transform_map_for_view(external_library, [:name, :symbols])
  end

  def build_question_by_question_config(
        %{question: question},
        all_testcases? \\ false
      ) do
    Map.merge(
      build_generic_question_fields(%{question: question}),
      build_question_content_by_config(
        %{question: question},
        all_testcases?
      )
    )
  end

  def build_question_with_answer_and_solution_if_ungraded(%{question: question}) do
    components = [
      build_question_by_question_config(%{
        question: question
      }),
      build_answer_fields_by_question_type(%{question: question}),
      build_solution_if_ungraded_by_config(%{question: question})
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
      maxXp: :max_xp,
      blocking: :blocking
    })
  end

  defp build_solution_if_ungraded_by_config(%{
         question: %{question: question, type: question_type, show_solution: show_solution}
       }) do
    if show_solution do
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
      lastModifiedAt: :last_modified_at,
      grader: grader_builder(grader),
      gradedAt: graded_at_builder(grader),
      xp: &((&1.xp || 0) + (&1.xp_adjustment || 0)),
      autogradingStatus: :autograding_status,
      autogradingResults: :autograding_results,
      comments: :comments
    })
  end

  defp build_contest_entry(entry) do
    transform_map_for_view(entry, %{
      submission_id: :submission_id,
      answer: :answer,
      score: :score
    })
  end

  def build_contest_leaderboard_entry(leaderboard_ans) do
    Map.put(
      transform_map_for_view(leaderboard_ans, %{
        submission_id: :submission_id,
        answer: :answer,
        student_name: :student_name,
        student_username: :student_username,
        rank: :rank
      }),
      "final_score",
      Float.round(leaderboard_ans.relative_score, 2)
    )
  end

  def build_popular_leaderboard_entry(leaderboard_ans) do
    Map.put(
      transform_map_for_view(leaderboard_ans, %{
        submission_id: :submission_id,
        answer: :answer,
        student_name: :student_name,
        student_username: :student_username,
        rank: :rank
      }),
      "final_score",
      Float.round(leaderboard_ans.popular_score, 2)
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

  defp build_testcases(all_testcases?) do
    if all_testcases? do
      &Enum.concat(
        Enum.concat(
          Enum.map(&1["public"], fn testcase -> build_testcase(testcase, "public") end),
          Enum.map(&1["opaque"], fn testcase -> build_testcase(testcase, "opaque") end)
        ),
        Enum.map(&1["secret"], fn testcase -> build_testcase(testcase, "secret") end)
      )
    else
      &Enum.concat(
        Enum.map(&1["public"], fn testcase -> build_testcase(testcase, "public") end),
        Enum.map(&1["opaque"], fn testcase -> build_testcase(testcase, "opaque") end)
      )
    end
  end

  defp build_question_content_by_config(
         %{
           question: %{
             question: question,
             type: question_type
           }
         },
         all_testcases?
       ) do
    case question_type do
      :programming ->
        transform_map_for_view(question, %{
          content: "content",
          prepend: "prepend",
          solutionTemplate: "template",
          postpend: "postpend",
          testcases: build_testcases(all_testcases?)
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
          scoreLeaderboard:
            &Enum.map(&1[:contest_leaderboard], fn entry ->
              build_contest_leaderboard_entry(entry)
            end),
          popularVoteLeaderboard:
            &Enum.map(&1[:popular_leaderboard], fn entry ->
              build_popular_leaderboard_entry(entry)
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
