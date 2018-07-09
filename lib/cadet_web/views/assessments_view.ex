defmodule CadetWeb.AssessmentsView do
  use CadetWeb, :view

  def render("index.json", %{assessments: assessments}) do
    render_many(assessments, CadetWeb.AssessmentsView, "overview.json", as: :assessment)
  end

  def render("overview.json", %{assessment: assessment}) do
    %{
      id: assessment.id,
      title: assessment.title,
      shortSummary: assessment.summary_short,
      openAt: DateTime.to_string(assessment.open_at),
      closeAt: DateTime.to_string(assessment.close_at),
      type: assessment.type,
      coverImage: Cadet.Assessments.Image.url({assessment.cover_picture, assessment}, :thumb)
    }
  end
end
