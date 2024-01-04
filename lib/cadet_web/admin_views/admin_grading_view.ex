defmodule CadetWeb.AdminGradingView do
  use CadetWeb, :view

  import CadetWeb.AssessmentsHelpers

  def render("show.json", %{answers: answers}) do
    render_many(answers, CadetWeb.AdminGradingView, "grading_info.json", as: :answer)
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
        CadetWeb.AdminGradingView,
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
        render_one(a, CadetWeb.AdminGradingView, "gradingsummaryassessment.json", as: :assessment),
      student: render_one(user, CadetWeb.AdminGradingView, "gradingsummaryuser.json", as: :cr),
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

  def render("grading_info.json", %{answer: answer}) do
    transform_map_for_view(answer, %{
      student: &extract_student_data(&1.submission.student),
      team: &extract_team_data(&1.submission.team),
      question: &build_grading_question/1,
      solution: &(&1.question.question["solution"] || ""),
      grade: &build_grade/1
    })
  end

  def render("grading_summary.json", %{cols: cols, summary: summary}) do
    %{cols: cols, rows: summary}
  end

  defp extract_student_data(nil), do: %{}
  defp extract_student_data(student) do
    transform_map_for_view(student, %{name: fn st -> st.user.name end, id: :id, username: fn st -> st.user.username end})
  end
  
  defp extract_team_member_data(team_member) do
    transform_map_for_view(team_member, %{name: &(&1.student.user.name), id: :id, username: &(&1.student.user.username)})
  end
  defp extract_team_data(nil), do: %{}
  defp extract_team_data(team) do
    members = team.team_members
    case members do
      [] -> nil
      _ -> Enum.map(members, &extract_team_member_data/1)
    end
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
