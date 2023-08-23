defmodule CadetWeb.AdminGradingView do
  use CadetWeb, :view

  import CadetWeb.AssessmentsHelpers

  def render("show.json", %{answers: answers}) do
    render_many(answers, CadetWeb.AdminGradingView, "grading_info.json", as: :answer)
  end

  def render("grading_info.json", %{answer: answer}) do
    transform_map_for_view(answer, %{
      student:
        &transform_map_for_view(&1.submission.student, %{
          name: fn st -> st.user.name end,
          id: :id,
          username: fn st -> st.user.username end
        }),
      question: &build_grading_question/1,
      solution: &(&1.question.question["solution"] || ""),
      grade: &build_grade/1
    })
  end

  def render("grading_summary.json", %{cols: cols, summary: summary}) do
    %{cols: cols, rows: summary}
  end

  defp build_grading_question(answer) do
    %{question: answer.question}
    |> build_question_by_question_config(true)
    |> Map.put(:answer, answer.answer["code"] || answer.answer["choice_id"])
    |> Map.put(:autogradingStatus, answer.autograding_status)
    |> Map.put(:autogradingResults, answer.autograding_results)
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
