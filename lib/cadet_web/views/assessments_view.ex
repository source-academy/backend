defmodule CadetWeb.AssessmentsView do
  use CadetWeb, :view
  use Timex

  import CadetWeb.AssessmentsHelpers

  def render("index.json", %{assessments: assessments}) do
    render_many(assessments, CadetWeb.AssessmentsView, "overview.json", as: :assessment)
  end

  def render("overview.json", %{assessment: assessment}) do
    transform_map_for_view(assessment, %{
      id: :id,
      title: :title,
      shortSummary: :summary_short,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      type: :type,
      story: :story,
      number: :number,
      reading: :reading,
      status: &(&1.user_status || "not_attempted"),
      gradingStatus: &(&1.grading_status || "none"),
      maxGrade: :max_grade,
      maxXp: :max_xp,
      xp: &(&1.xp || 0),
      grade: &(&1.grade || 0),
      coverImage: :cover_picture,
      private: &password_protected?(&1.password)
    })
  end

  def render("show.json", %{assessment: assessment}) do
    transform_map_for_view(
      assessment,
      %{
        id: :id,
        title: :title,
        type: :type,
        story: :story,
        number: :number,
        reading: :reading,
        longSummary: :summary_long,
        missionPDF: &Cadet.Assessments.Upload.url({&1.mission_pdf, &1}),
        questions:
          &Enum.map(&1.questions, fn question ->
            build_question_with_answer_and_solution_if_ungraded(%{
              question: question,
              assessment: assessment
            })
          end)
      }
    )
  end

  defp password_protected?(nil), do: false

  defp password_protected?(_), do: true
end
