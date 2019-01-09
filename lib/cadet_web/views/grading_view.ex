defmodule CadetWeb.GradingView do
  use CadetWeb, :view

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
      status: :status
    })
  end

  def render("grading_info.json", %{answer: answer}) do
    transform_map_for_view(answer, %{
      student: &transform_map_for_view(&1.submission.student, [:name, :id]),
      question:
        &Map.put(
          CadetWeb.AssessmentsView.build_question(%{question: &1.question}),
          :answer,
          &1.answer["code"] || &1.answer["choice_id"]
        ),
      solution: &(&1.question.question["solution"] || ""),
      maxGrade: & &1.question.max_grade,
      maxXp: & &1.question.max_xp,
      grade: &build_grade/1
    })
  end

  defp build_grade(answer = %{grader: grader}) do
    transform_map_for_view(answer, %{
      grader: grader_builder(grader),
      gradedAt: graded_at_builder(grader),
      grade: :grade,
      adjustment: :adjustment,
      comment: :comment,
      xp: :xp,
      xpAdjustment: :xp_adjustment
    })
  end
end
