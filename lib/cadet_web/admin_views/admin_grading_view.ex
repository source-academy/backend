defmodule CadetWeb.AdminGradingView do
  use CadetWeb, :view

  import CadetWeb.AssessmentsHelpers
  alias CadetWeb.AICodeAnalysisController

  def render("show.json", %{course: course, answers: answers, assessment: assessment}) do
    %{
      assessment:
        render_one(assessment, CadetWeb.AdminGradingView, "assessment.json", as: :assessment),
      answers:
        render_many(answers, CadetWeb.AdminGradingView, "grading_info.json",
          as: :answer,
          course: course,
          assessment: assessment
        ),
      enable_llm_grading: course.enable_llm_grading
    }
  end

  def render("assessment.json", %{assessment: assessment}) do
    %{
      id: assessment.id,
      title: assessment.title,
      summaryShort: assessment.summary_short,
      summaryLong: assessment.summary_long,
      coverPicture: assessment.cover_picture,
      number: assessment.number,
      story: assessment.story,
      reading: assessment.reading
    }
  end

  def render("gradingsummaries.json", %{
        count: count,
        data: %{
          users: users,
          assessments: assessments,
          submissions: submissions,
          teams: teams,
          team_members: team_members
        }
      }) do
    %{
      count: count,
      data:
        for submission <- submissions do
          user = users |> Enum.find(&(&1.id == submission.student_id))
          assessment = assessments |> Enum.find(&(&1.id == submission.assessment_id))
          team = teams |> Enum.find(&(&1.id == submission.team_id))
          team_members = team_members |> Enum.filter(&(&1.team_id == submission.team_id))

          team_member_users =
            team_members
            |> Enum.map(fn team_member ->
              users |> Enum.find(&(&1.id == team_member.student_id))
            end)

          render(
            CadetWeb.AdminGradingView,
            "gradingsummary.json",
            %{
              user: user,
              assessment: assessment,
              submission: submission,
              team: team,
              team_members: team_member_users,
              unsubmitter:
                case submission.unsubmitted_by_id do
                  nil -> nil
                  _ -> users |> Enum.find(&(&1.id == submission.unsubmitted_by_id))
                end
            }
          )
        end
    }
  end

  def render("gradingsummary.json", %{
        user: user,
        assessment: a,
        submission: s,
        team: team,
        team_members: team_members,
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
      isGradingPublished: :is_grading_published,
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
      team:
        render_one(team, CadetWeb.AdminGradingView, "gradingsummaryteam.json",
          as: :team,
          assigns: %{team_members: team_members}
        ),
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

  def render("gradingsummaryteam.json", %{team: team, assigns: %{team_members: team_members}}) do
    %{
      id: team.id,
      team_members:
        render_many(team_members, CadetWeb.AdminGradingView, "gradingsummaryuser.json", as: :cr)
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

  def render("grading_info.json", %{answer: answer, course: course, assessment: assessment}) do
    transform_map_for_view(answer, %{
      id: & &1.id,
      prompts: &build_prompts(&1, course, assessment),
      ai_comments: &extract_ai_comments_per_answer(&1.id, &1.ai_comments),
      student: &extract_student_data(&1.submission.student),
      team: &extract_team_data(&1.submission.team),
      question: &build_grading_question(&1, course, assessment),
      solution: &(&1.question.question["solution"] || ""),
      grade: &build_grade/1
    })
  end

  def render("grading_summary.json", %{cols: cols, summary: summary}) do
    %{cols: cols, rows: summary}
  end

  defp extract_ai_comments_per_answer(id, ai_comments) do
    matching_comment =
      ai_comments
      # Equivalent to fn comment -> comment.question_id == question_id end
      |> Enum.find(&(&1.answer_id == id))

    case matching_comment do
      nil -> nil
      comment -> %{response: comment.response, insertedAt: comment.inserted_at}
    end
  end

  defp extract_student_data(nil), do: %{}

  defp extract_student_data(student) do
    transform_map_for_view(student, %{
      name: fn st -> st.user.name end,
      id: :id,
      username: fn st -> st.user.username end
    })
  end

  defp extract_team_member_data(team_member) do
    transform_map_for_view(team_member, %{
      name: & &1.student.user.name,
      id: :id,
      username: & &1.student.user.username
    })
  end

  defp extract_team_data(nil), do: %{}

  defp extract_team_data(team) do
    members = team.team_members

    case members do
      [] -> nil
      _ -> Enum.map(members, &extract_team_member_data/1)
    end
  end

  defp build_grading_question(answer, course, assessment) do
    %{question: answer.question |> Map.delete(:llm_prompt)}
    |> build_question_by_question_config(true)
    |> Map.put(:answer, answer.answer["code"] || answer.answer["choice_id"])
    |> Map.put(:autogradingStatus, answer.autograding_status)
    |> Map.put(:autogradingResults, answer.autograding_results)
  end

  defp build_prompts(answer, course, assessment) do
    if course.enable_llm_grading do
      AICodeAnalysisController.create_final_messages(
        course.llm_course_level_prompt,
        assessment.llm_assessment_prompt,
        answer
      )
    else
      []
    end
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
