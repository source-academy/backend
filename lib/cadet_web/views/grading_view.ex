defmodule CadetWeb.GradingView do
  use CadetWeb, :view

  def render("index.json", %{submissions: submissions}) do
    render_many(submissions, CadetWeb.GradingView, "submission.json", as: :submission)
  end

  def render("submission.json", %{submission: submission}) do
    %{
      xp: submission.xp,
      submissionId: submission.id,
      student: %{
        name: submission.student.name,
        id: submission.student.id
      },
      assessment: %{
        type: submission.assessment.type,
        max_xp: submission.assessment.max_xp,
        id: submission.assessment.id
      }
    }
  end
end
