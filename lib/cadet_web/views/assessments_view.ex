defmodule CadetWeb.AssessmentsView do
  use CadetWeb, :view
  use Timex

  import CadetWeb.AssessmentsHelpers

  def render("index.json", %{assessments: assessments}) do
    render_many(assessments, CadetWeb.AssessmentsView, "overview.json", as: :assessment)
  end

  def render("gradingsummaries.json", %{
        users: users,
        assessments: assessments,
        submissions: submissions
      }) do
    for submission <- submissions do
      user = users |> Enum.find(&(&1.id == submission.student_id))
      assessment = assessments |> Enum.find(&(&1.id == submission.assessment_id))

      render(
        CadetWeb.AssessmentsView,
        "gradingsummary.json",
        %{
          user: user,
          assessment: assessment,
          submission: submission,
          unsubmitter:
            case submission.unsubmitted_by_id do
              nil -> nil
              _ -> users |> Enum.find(&(&1.id == submission.unsubmitted_by_id))
            end
        }
      )
    end
  end

  def render("gradingsummary.json", %{
        user: user,
        assessment: a,
        submission: s,
        unsubmitter: unsubmitter
      }) do
    s
    |> transform_map_for_view(%{
      id: :id,
      status: :status,
      unsubmittedAt: :unsubmitted_at,
      xp: :xp,
      xpAdjustment: :xp_adjustment,
      xpBonus: :xp_bonus,
      gradedCount:
        &case &1.graded_count do
          nil -> 0
          x -> x
        end
    })
    |> Map.merge(%{
      assessment:
        render_one(a, CadetWeb.AssessmentsView, "gradingsummaryassessment.json", as: :assessment),
      student: render_one(user, CadetWeb.AssessmentsView, "gradingsummaryuser.json", as: :cr),
      unsubmittedBy:
        case unsubmitter do
          nil -> nil
          cr -> transform_map_for_view(cr, %{id: :id, name: & &1.user.name})
        end
    })
  end

  def render("gradingsummaryassessment.json", %{assessment: a}) do
    %{
      id: a.id,
      title: a.title,
      assessmentNumber: a.number,
      isManuallyGraded: a.config.is_manually_graded,
      type: a.config.type,
      maxXp: a.questions |> Enum.map(& &1.max_xp) |> Enum.sum(),
      questionCount: a.questions |> Enum.count()
    }
  end

  def render("gradingsummaryuser.json", %{cr: cr}) do
    %{
      id: cr.id,
      name: cr.user.name,
      username: cr.user.username,
      groupName:
        case cr.group do
          nil -> nil
          _ -> cr.group.name
        end,
      groupLeaderId:
        case cr.group do
          nil -> nil
          _ -> cr.group.leader_id
        end
    }
  end

  def render("overview.json", %{assessment: assessment}) do
    transform_map_for_view(assessment, %{
      id: :id,
      courseId: :course_id,
      title: :title,
      shortSummary: :summary_short,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      type: & &1.config.type,
      isManuallyGraded: & &1.config.is_manually_graded,
      story: :story,
      number: :number,
      reading: :reading,
      status: &(&1.user_status || "not_attempted"),
      maxXp: :max_xp,
      xp: &(&1.xp || 0),
      coverImage: :cover_picture,
      private: &password_protected?(&1.password),
      isPublished: :is_published,
      questionCount: :question_count,
      gradedCount: &(&1.graded_count || 0)
    })
  end

  def render("show.json", %{assessment: assessment}) do
    transform_map_for_view(
      assessment,
      %{
        id: :id,
        courseId: :course_id,
        title: :title,
        type: & &1.config.type,
        story: :story,
        number: :number,
        reading: :reading,
        longSummary: :summary_long,
        missionPDF: &Cadet.Assessments.Upload.url({&1.mission_pdf, &1}),
        questions:
          &Enum.map(&1.questions, fn question ->
            map =
              build_question_with_answer_and_solution_if_ungraded(%{
                question: question
              })

            map
          end)
      }
    )
  end

  defp password_protected?(nil), do: false

  defp password_protected?(_), do: true
end
