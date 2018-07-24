defmodule CadetWeb.GradingView do
  use CadetWeb, :view

  def render("index.json", %{submissions: submissions}) do
    render_many(submissions, CadetWeb.GradingView, "submission.json", as: :submission)
  end

  def render("show.json", %{answers: answers}) do
    render_many(answers, CadetWeb.GradingView, "grading_info.json", as: :answer)
  end

  def render("submission.json", %{submission: submission}) do
    %{
      grade: submission.grade,
      submissionId: submission.id,
      student: %{
        name: submission.student.name,
        id: submission.student.id
      },
      assessment: %{
        type: submission.assessment.type,
        max_grade: submission.assessment.max_grade,
        id: submission.assessment.id
      }
    }
  end

  def render("grading_info.json", %{answer: answer}) do
    transform_map_for_view(answer, %{
      question:
        &Map.put(
          CadetWeb.AssessmentsView.build_question(%{question: &1.question}),
          :answer,
          &1.answer["code"]
        ),
      max_grade: & &1.question.max_grade,
      grade: &transform_map_for_view(&1, [:grade, :adjustment, :comment])
    })
  end
end
