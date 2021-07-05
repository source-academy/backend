defmodule CadetWeb.AdminGradingView do
  use CadetWeb, :view

  import CadetWeb.AssessmentsHelpers

  def render("show.json", %{answers: answers}) do
    render_many(answers, CadetWeb.AdminGradingView, "grading_info.json", as: :answer)
  end

  def render("grading_info.json", %{answer: answer}) do
    transform_map_for_view(answer, %{
      student:
        &transform_map_for_view(&1.submission.student, %{name: fn st -> st.user.name end, id: :id}),
      question: &build_grading_question/1,
      solution: &(&1.question.question["solution"] || ""),
      grade: &build_grade/1
    })
  end

  def render("grading_summary.json", %{summary: summary}) do
    render_many(summary, CadetWeb.AdminGradingView, "grading_summary_entry.json", as: :entry)
  end

  def render("grading_summary_entry.json", %{entry: entry}) do
    transform_map_for_view(entry, %{
      groupName: :group_name,
      leaderName: :leader_name,
      ungradedMissions: :ungraded_missions,
      submittedMissions: :submitted_missions,
      ungradedSidequests: :ungraded_sidequests,
      submittedSidequests: :submitted_sidequests
    })
  end

  defp build_grading_question(answer) do
    results = build_autograding_results(answer.autograding_results)

    %{question: answer.question}
    |> build_question_by_question_config(true)
    |> Map.put(:answer, answer.answer["code"] || answer.answer["choice_id"])
    |> Map.put(:autogradingStatus, answer.autograding_status)
    |> Map.put(:autogradingResults, results)
  end

  defp build_autograding_results(nil), do: nil

  defp build_autograding_results(results) do
    Enum.map(results, &build_result/1)
  end

  defp build_grade(answer = %{grader: grader}) do
    transform_map_for_view(answer, %{
      grader: grader_builder(grader),
      gradedAt: graded_at_builder(grader),
      xp: :xp,
      xpAdjustment: :xp_adjustment,
      comments: :comments
    })
  end
end
