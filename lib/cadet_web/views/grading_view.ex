defmodule CadetWeb.GradingView do
  use CadetWeb, :view

  def render("index.json", %{submissions: submissions}) do
    render_many(submissions, CadetWeb.GradingView, "submission.json", as: :submission)
  end

  def render("submission.json", %{submission: submission}) do
    %{
      submissionId: submission.id,
      missionId: submission.assessment_id,
      studentId: submission.student_id
    }
  end
end
