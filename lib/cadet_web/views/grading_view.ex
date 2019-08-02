defmodule CadetWeb.GradingView do
  use CadetWeb, :view

  import CadetWeb.AssessmentsHelpers

  def render("index.json", %{submissions: submissions}) do
    render_many(submissions, CadetWeb.GradingView, "submission.json", as: :submission)
  end

  def render("show.json", %{answers: answers}) do
    render_many(answers, CadetWeb.GradingView, "grading_info.json", as: :answer)
  end

  def render("submission.json", %{submission: submission}) do
    transform_map_for_view(submission, %{
      grade: :grade,
      xp: :xp,
      xpAdjustment: :xp_adjustment,
      xpBonus: :xp_bonus,
      adjustment: :adjustment,
      id: :id,
      student: &transform_map_for_view(&1.student, [:name, :id]),
      assessment:
        &transform_map_for_view(&1.assessment, %{
          type: :type,
          maxGrade: :max_grade,
          maxXp: :max_xp,
          id: :id,
          title: :title,
          coverImage: :cover_picture
        }),
      groupName: :group_name,
      status: :status,
      questionCount: :question_count,
      gradedCount: &(&1.graded_count || 0),
      gradingStatus: &(&1.grading_status || "excluded"),
      unsubmittedBy: &unsubmitted_by_builder(&1.unsubmitted_by),
      unsubmittedAt: &format_datetime(&1.unsubmitted_at)
    })
  end

  def render("grading_info.json", %{answer: answer}) do
    transform_map_for_view(answer, %{
      student: &transform_map_for_view(&1.submission.student, [:name, :id]),
      question: &build_grading_question/1,
      solution: &(&1.question.question["solution"] || ""),
      grade: &build_grade/1
    })
  end

  defp build_grading_question(answer) do
    results = build_autograding_results(answer.autograding_results)

    %{question: answer.question}
    |> build_question()
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
      grade: :grade,
      adjustment: :adjustment,
      roomId: :room_id,
      xp: :xp,
      xpAdjustment: :xp_adjustment
    })
  end
end
