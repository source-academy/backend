defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]
  alias Cadet.Incentives.{Achievement, Achievements, GoalProgress}
  import Ecto.Query

  require Logger

  alias Cadet.Accounts.{
    Notification,
    Notifications,
    User,
    Teams,
    Team,
    TeamMember,
    CourseRegistration,
    CourseRegistrations
  }

  alias Cadet.Assessments.{Answer, Assessment, Query, Question, Submission, SubmissionVotes}
  alias Cadet.Autograder.GradingJob
  alias Cadet.Courses.{Group, AssessmentConfig}
  alias Cadet.Jobs.Log
  alias Cadet.ProgramAnalysis.Lexer
  alias Ecto.{Multi, Changeset}
  alias Timex.Duration

  require Decimal

  @open_all_assessment_roles ~w(staff admin)a

  # These roles can save and finalise answers for closed assessments and
  # submitted answers
  @bypass_closed_roles ~w(staff admin)a

  def delete_assessment(id) do
    Logger.info("Attempting to delete assessment #{id}")
    assessment = Repo.get(Assessment, id)

    is_voted_on =
      Question
      |> where(type: :voting)
      |> join(:inner, [q], asst in assoc(q, :assessment))
      |> where(
        [q, asst],
        q.question["contest_number"] == ^assessment.number and
          asst.course_id == ^assessment.course_id
      )
      |> Repo.exists?()

    if is_voted_on do
      Logger.error("Cannot delete assessment #{id} - contest voting is still active")
      {:error, {:bad_request, "Contest voting for this contest is still up"}}
    else
      Logger.info("Deleting submissions associated with assessment #{id}")

      Submission
      |> where(assessment_id: ^id)
      |> delete_submission_association(id)

      Logger.info("Deleting questions associated with assessment #{id}")

      Question
      |> where(assessment_id: ^id)
      |> Repo.all()
      |> Enum.each(fn q ->
        delete_submission_votes_association(q)
      end)

      Logger.info("Deleting assessment #{id}")
      result = Repo.delete(assessment)

      case result do
        {:ok, _} ->
          Logger.info("Successfully deleted assessment #{id}")

        {:error, changeset} ->
          Logger.error("Failed to delete assessment #{id}: #{full_error_messages(changeset)}")
      end

      result
    end
  end

  defp delete_submission_votes_association(question) do
    Logger.info("Deleting submission votes for question #{question.id}")

    SubmissionVotes
    |> where(question_id: ^question.id)
    |> Repo.delete_all()
  end

  defp delete_submission_association(submissions, assessment_id) do
    Logger.info("Deleting answers for submissions associated with assessment #{assessment_id}")

    submissions
    |> Repo.all()
    |> Enum.each(fn submission ->
      Answer
      |> where(submission_id: ^submission.id)
      |> Repo.delete_all()
    end)

    Logger.info("Deleting notifications for assessment #{assessment_id}")

    Notification
    |> where(assessment_id: ^assessment_id)
    |> Repo.delete_all()

    Logger.info("Deleting submissions for assessment #{assessment_id}")
    Repo.delete_all(submissions)
  end

  @spec user_max_xp(CourseRegistration.t()) :: integer()
  def user_max_xp(cr = %CourseRegistration{id: cr_id}) do
    Logger.info("Calculating maximum XP for user #{cr.user_id} in course #{cr.course_id}")

    result =
      Submission
      |> where(status: ^:submitted)
      |> where(student_id: ^cr_id)
      |> join(
        :inner,
        [s],
        a in subquery(Query.all_assessments_with_max_xp()),
        on: s.assessment_id == a.id
      )
      |> select([_, a], sum(a.max_xp))
      |> Repo.one()
      |> decimal_to_integer()

    Logger.info("Calculated maximum XP for user #{cr.user_id}: #{result}")
    result
  end

  def assessments_total_xp(%CourseRegistration{id: cr_id}) do
    Logger.info("Calculating total XP for assessments for user #{cr_id}")
    teams = find_teams(cr_id)
    submission_ids = get_submission_ids(cr_id, teams)

    Logger.info("Fetching XP for submissions")

    submission_xp =
      Submission
      |> where(
        [s],
        s.id in subquery(submission_ids)
      )
      |> where(is_grading_published: true)
      |> join(:inner, [s], a in Answer, on: s.id == a.submission_id)
      |> group_by([s], s.id)
      |> select([s, a], %{
        # grouping by submission, so s.xp_bonus will be the same, but we need an
        # aggregate function
        total_xp: sum(a.xp) + sum(a.xp_adjustment) + max(s.xp_bonus)
      })

    total =
      submission_xp
      |> subquery
      |> select([s], %{
        total_xp: sum(s.total_xp)
      })
      |> Repo.one()

    Logger.info("Total XP calculated: #{decimal_to_integer(total.total_xp)}")
    # for {key, val} <- total, into: %{}, do: {key, decimal_to_integer(val)}
    decimal_to_integer(total.total_xp)
  end

  def user_total_xp(course_id, user_id, course_reg_id) do
    Logger.info("Calculating total XP for user #{user_id} in course #{course_id}")
    user_course = CourseRegistrations.get_user_course(user_id, course_id)

    total_achievement_xp = Achievements.achievements_total_xp(course_id, course_reg_id)
    total_assessment_xp = assessments_total_xp(user_course)

    Logger.info("Total XP for user #{user_id}: #{total_achievement_xp + total_assessment_xp}")
    total_achievement_xp + total_assessment_xp
  end

  def all_user_total_xp(course_id, options \\ %{}) do
    Logger.info("Fetching total XP for all users in course #{course_id}")

    include_admin_staff_users = fn q ->
      if options[:include_admin_staff],
        do: q,
        else: where(q, [_, cr], cr.role == "student")
    end

    # get all users even if they have 0 xp
    course_userid_query =
      User
      |> join(:inner, [u], cr in CourseRegistration, on: cr.user_id == u.id)
      |> where([_, cr], cr.course_id == ^course_id)
      |> include_admin_staff_users.()
      |> select([u, cr], %{
        id: u.id,
        cr_id: cr.id
      })

    achievements_xp_query =
      from(u in User,
        join: cr in CourseRegistration,
        on: cr.user_id == u.id and cr.course_id == ^course_id,
        left_join: a in Achievement,
        on: a.course_id == cr.course_id,
        left_join: j in assoc(a, :goals),
        left_join: g in assoc(j, :goal),
        left_join: p in GoalProgress,
        on: p.goal_uuid == g.uuid and p.course_reg_id == cr.id,
        where:
          a.course_id == ^course_id and p.completed and
            p.count == g.target_count,
        group_by: [u.id, u.name, u.username, cr.id],
        select: %{
          user_id: u.id,
          achievements_xp:
            fragment(
              "CASE WHEN bool_and(?) THEN ? ELSE ? END",
              a.is_variable_xp,
              sum(p.count),
              max(a.xp)
            )
        }
      )

    submissions_xp_query =
      course_userid_query
      |> subquery()
      |> join(:left, [u], tm in TeamMember, on: tm.student_id == u.cr_id)
      |> join(:left, [u, tm], s in Submission, on: s.student_id == u.cr_id or s.team_id == tm.id)
      |> join(:left, [u, tm, s], a in Answer, on: s.id == a.submission_id)
      |> where([_, _, s, _], s.is_grading_published == true)
      |> group_by([u, _, s, _], [u.id, s.id])
      |> select([u, _, s, a], %{
        user_id: u.id,
        submission_xp: sum(a.xp) + sum(a.xp_adjustment) + max(s.xp_bonus)
      })
      |> subquery()
      |> group_by([t], t.user_id)
      |> select([t], %{
        user_id: t.user_id,
        submission_xp: sum(t.submission_xp)
      })

    total_xp_query =
      course_userid_query
      |> subquery()
      |> join(:inner, [cu], u in User, on: cu.id == u.id)
      |> join(:left, [cu, _], ax in subquery(achievements_xp_query), on: cu.id == ax.user_id)
      |> join(:left, [cu, _, _], sx in subquery(submissions_xp_query), on: cu.id == sx.user_id)
      |> select([_, u, ax, sx], %{
        user_id: u.id,
        name: u.name,
        username: u.username,
        total_xp:
          fragment(
            "COALESCE(?, 0) + COALESCE(?, 0)",
            ax.achievements_xp,
            sx.submission_xp
          )
      })
      |> order_by(desc: fragment("total_xp"))

    # add rank index
    ranked_xp_query =
      from(t in subquery(total_xp_query),
        select_merge: %{
          rank: fragment("RANK() OVER (ORDER BY total_xp DESC)")
        },
        limit: ^options[:limit],
        offset: ^options[:offset]
      )

    count_query =
      total_xp_query
      |> subquery()
      |> select([t], count(t.user_id))

    {status, {rows, total_count}} =
      Repo.transaction(fn ->
        users =
          Enum.map(Repo.all(ranked_xp_query), fn user ->
            %{user | total_xp: Decimal.to_integer(user.total_xp)}
          end)

        count = Repo.one(count_query)
        {users, count}
      end)

    Logger.info("Successfully fetched total XP for #{total_count} users")

    %{
      users: rows,
      total_count: total_count
    }
  end

  defp decimal_to_integer(decimal) do
    if Decimal.is_decimal(decimal) do
      Decimal.to_integer(decimal)
    else
      0
    end
  end

  def user_current_story(cr = %CourseRegistration{}) do
    {:ok, %{result: story}} =
      Multi.new()
      |> Multi.run(:unattempted, fn _repo, _ ->
        {:ok, get_user_story_by_type(cr, :unattempted)}
      end)
      |> Multi.run(:result, fn _repo, %{unattempted: unattempted_story} ->
        if unattempted_story do
          {:ok, %{play_story?: true, story: unattempted_story}}
        else
          {:ok, %{play_story?: false, story: get_user_story_by_type(cr, :attempted)}}
        end
      end)
      |> Repo.transaction()

    story
  end

  @spec get_user_story_by_type(CourseRegistration.t(), :unattempted | :attempted) ::
          String.t() | nil
  def get_user_story_by_type(%CourseRegistration{id: cr_id}, type)
      when is_atom(type) do
    filter_and_sort = fn query ->
      case type do
        :unattempted ->
          query
          |> where([_, s], is_nil(s.id))
          |> order_by([a], asc: a.open_at)

        :attempted ->
          query |> order_by([a], desc: a.close_at)
      end
    end

    Assessment
    |> where(is_published: true)
    |> where([a], not is_nil(a.story))
    |> where([a], a.open_at <= from_now(0, "second") and a.close_at >= from_now(0, "second"))
    |> join(:left, [a], s in Submission, on: s.assessment_id == a.id and s.student_id == ^cr_id)
    |> filter_and_sort.()
    |> order_by([a], a.config_id)
    |> select([a], a.story)
    |> first()
    |> Repo.one()
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{password: nil},
        cr = %CourseRegistration{},
        nil
      ) do
    assessment_with_questions_and_answers(assessment, cr)
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{password: nil},
        cr = %CourseRegistration{},
        _
      ) do
    assessment_with_questions_and_answers(assessment, cr)
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{password: password},
        cr = %CourseRegistration{},
        given_password
      ) do
    cond do
      Timex.compare(Timex.now(), assessment.close_at) >= 0 ->
        assessment_with_questions_and_answers(assessment, cr)

      match?({:ok, _}, find_submission(cr, assessment)) ->
        assessment_with_questions_and_answers(assessment, cr)

      given_password == nil ->
        {:error, {:forbidden, "Missing Password."}}

      password == given_password ->
        find_or_create_submission(cr, assessment)
        assessment_with_questions_and_answers(assessment, cr)

      true ->
        {:error, {:forbidden, "Invalid Password."}}
    end
  end

  def assessment_with_questions_and_answers(id, cr = %CourseRegistration{}, password)
      when is_ecto_id(id) do
    Logger.info(
      "Fetching assessment #{id} with questions and answers for user #{cr.user_id} in course #{cr.course_id}"
    )

    role = cr.role

    assessment =
      if role in @open_all_assessment_roles do
        Assessment
        |> where(id: ^id)
        |> preload(:config)
        |> Repo.one()
      else
        Assessment
        |> where(id: ^id)
        |> where(is_published: true)
        |> preload(:config)
        |> Repo.one()
      end

    if assessment do
      result = assessment_with_questions_and_answers(assessment, cr, password)

      case result do
        {:ok, _} ->
          Logger.info("Successfully retrieved assessment #{id} for user #{cr.user_id}")

        {:error, {status, message}} ->
          Logger.error(
            "Failed to retrieve assessment #{id} for user #{cr.user_id}: #{status} - #{message}"
          )
      end

      result
    else
      Logger.error("Assessment #{id} not found or not published for user #{cr.user_id}")
      {:error, {:bad_request, "Assessment not found"}}
    end
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{id: id},
        course_reg = %CourseRegistration{role: role, id: user_id}
      ) do
    Logger.info(
      "Fetching assessment with questions and answers for assessment #{id} and user #{user_id}"
    )

    team_id =
      case find_team(id, user_id) do
        {:ok, nil} ->
          Logger.info("No team found for user #{user_id} in assessment #{id}")
          -1

        {:ok, team} ->
          Logger.info("Team found for user #{user_id} in assessment #{id}: Team ID #{team.id}")

          team.id

        {:error, :team_not_found} ->
          Logger.error("Team not found for user #{user_id} in assessment #{id}")
          -1
      end

    if Timex.compare(Timex.now(), assessment.open_at) >= 0 or role in @open_all_assessment_roles do
      Logger.info("Assessment #{id} is open or user #{user_id} has access")

      answer_query =
        Answer
        |> join(:inner, [a], s in assoc(a, :submission))
        |> where([_, s], s.student_id == ^course_reg.id or s.team_id == ^team_id)

      visible_entries =
        Assessment
        |> join(:inner, [a], c in assoc(a, :course))
        |> where([a, c], a.id == ^id)
        |> select([a, c], c.top_contest_leaderboard_display)
        |> Repo.one()

      Logger.debug("Visible entries for assessment #{id}: #{visible_entries}")

      questions =
        Question
        |> where(assessment_id: ^id)
        |> join(:left, [q], a in subquery(answer_query), on: q.id == a.question_id)
        |> join(:left, [_, a], g in assoc(a, :grader))
        |> join(:left, [_, _, g], u in assoc(g, :user))
        |> select([q, a, g, u], {q, a, g, u})
        |> order_by(:display_order)
        |> Repo.all()
        |> Enum.map(fn
          {q, nil, _, _} -> %{q | answer: %Answer{grader: nil}}
          {q, a, nil, _} -> %{q | answer: %Answer{a | grader: nil}}
          {q, a, g, u} -> %{q | answer: %Answer{a | grader: %CourseRegistration{g | user: u}}}
        end)
        |> load_contest_voting_entries(course_reg, assessment, visible_entries)

      Logger.debug("Questions loaded for assessment #{id}")

      is_grading_published =
        Submission
        |> where(assessment_id: ^id)
        |> where([s], s.student_id == ^course_reg.id or s.team_id == ^team_id)
        |> select([s], s.is_grading_published)
        |> Repo.one()

      Logger.debug("Grading published status for assessment #{id}: #{is_grading_published}")

      assessment =
        assessment
        |> Map.put(:questions, questions)
        |> Map.put(:is_grading_published, is_grading_published)

      Logger.info(
        "Successfully fetched assessment #{id} with questions and answers for user #{course_reg.id}"
      )

      {:ok, assessment}
    else
      Logger.error("Assessment #{id} is not open for user #{course_reg.id}")
      {:error, {:forbidden, "Assessment not open"}}
    end
  end

  def assessment_with_questions_and_answers(id, cr = %CourseRegistration{}) do
    assessment_with_questions_and_answers(id, cr, nil)
  end

  @doc """
  Returns a list of assessments with all fields and an indicator showing whether it has been attempted
  by the supplied user
  """
  def all_assessments(cr = %CourseRegistration{}) do
    Logger.info("Retrieving all assessments for user #{cr.user_id} in course #{cr.course_id}")

    teams = find_teams(cr.id)
    Logger.debug("Found teams for user #{cr.user_id}: #{inspect(teams)}")

    submission_ids = get_submission_ids(cr.id, teams)
    Logger.debug("Submission IDs for user #{cr.user_id}: #{inspect(submission_ids)}")

    submission_aggregates =
      Submission
      |> join(:left, [s], ans in Answer, on: ans.submission_id == s.id)
      |> where(
        [s],
        s.id in subquery(submission_ids)
      )
      |> group_by([s], s.assessment_id)
      |> select([s, ans], %{
        assessment_id: s.assessment_id,
        # s.xp_bonus should be the same across the group, but we need an aggregate function here
        xp: fragment("? + ? + ?", sum(ans.xp), sum(ans.xp_adjustment), max(s.xp_bonus)),
        graded_count: ans.id |> count() |> filter(not is_nil(ans.grader_id))
      })

    Logger.debug("Submission aggregates query prepared for user #{cr.user_id}")

    submission_status =
      Submission
      |> where(
        [s],
        s.id in subquery(submission_ids)
      )
      |> select([s], [:assessment_id, :status, :is_grading_published])

    Logger.debug("Submission status query prepared for user #{cr.user_id}")

    assessments =
      cr.course_id
      |> Query.all_assessments_with_aggregates()
      |> subquery()
      |> join(
        :left,
        [a],
        sa in subquery(submission_aggregates),
        on: a.id == sa.assessment_id
      )
      |> join(:left, [a, _], s in subquery(submission_status), on: a.id == s.assessment_id)
      |> select([a, sa, s], %{
        a
        | xp: sa.xp,
          graded_count: sa.graded_count,
          user_status: s.status,
          is_grading_published: s.is_grading_published
      })
      |> filter_published_assessments(cr)
      |> order_by(:open_at)
      |> preload(:config)
      |> Repo.all()

    Logger.info(
      "Successfully retrieved #{length(assessments)} assessments for user #{cr.user_id}"
    )

    {:ok, assessments}
  end

  defp get_submission_ids(cr_id, teams) do
    Logger.debug("Fetching submission IDs for user #{cr_id} and teams #{inspect(teams)}")

    from(s in Submission,
      where: s.student_id == ^cr_id or s.team_id in ^Enum.map(teams, & &1.id),
      select: s.id
    )
  end

  defp is_voting_assigned(assessment_ids) do
    Logger.debug("Checking if voting is assigned for assessment IDs: #{inspect(assessment_ids)}")

    voting_assigned_question_ids =
      SubmissionVotes
      |> select([v], v.question_id)
      |> Repo.all()

    Logger.debug("Voting assigned question IDs: #{inspect(voting_assigned_question_ids)}")

    # Map of assessment_id to boolean
    voting_assigned_assessment_ids =
      Question
      |> where(type: :voting)
      |> where([q], q.id in ^voting_assigned_question_ids)
      |> where([q], q.assessment_id in ^assessment_ids)
      |> select([q], q.assessment_id)
      |> distinct(true)
      |> Repo.all()

    Logger.debug("Voting assigned assessment IDs: #{inspect(voting_assigned_assessment_ids)}")

    Enum.reduce(assessment_ids, %{}, fn id, acc ->
      Map.put(acc, id, Enum.member?(voting_assigned_assessment_ids, id))
    end)
  end

  @doc """
  A helper function which removes grading information from all assessments
  if it's grading is not published.
  """
  def format_all_assessments(assessments) do
    is_voting_assigned_map =
      assessments
      |> Enum.map(& &1.id)
      |> is_voting_assigned()

    Enum.map(assessments, fn a ->
      a = Map.put(a, :is_voting_published, Map.get(is_voting_assigned_map, a.id, false))

      if a.is_grading_published do
        a
      else
        a
        |> Map.put(:xp, 0)
        |> Map.put(:graded_count, 0)
      end
    end)
  end

  @doc """
  A helper function which removes grading information from the assessment
  if it's grading is not published.
  """
  def format_assessment_with_questions_and_answers(assessment) do
    if assessment.is_grading_published do
      assessment
    else
      %{
        assessment
        | questions:
            Enum.map(assessment.questions, fn q ->
              %{
                q
                | answer: %{
                    q.answer
                    | xp: 0,
                      xp_adjustment: 0,
                      autograding_status: :none,
                      autograding_results: [],
                      grader: nil,
                      grader_id: nil,
                      comments: nil
                  }
              }
            end)
      }
    end
  end

  def filter_published_assessments(assessments, cr) do
    role = cr.role

    case role do
      :student ->
        Logger.debug("Filtering assessments for student role")
        where(assessments, is_published: true)

      _ ->
        Logger.debug("No filtering applied for role #{role}")
        assessments
    end
  end

  def create_assessment(params) do
    %Assessment{}
    |> Assessment.changeset(params)
    |> Repo.insert()
  end

  @doc """
  The main function that inserts or updates assessments from the XML Parser
  """
  @spec insert_or_update_assessments_and_questions(map(), [map()], boolean()) ::
          {:ok, any()}
          | {:error, Ecto.Multi.name(), any(), %{optional(Ecto.Multi.name()) => any()}}
  def insert_or_update_assessments_and_questions(
        assessment_params,
        questions_params,
        force_update
      ) do
    Logger.info(
      "Starting insert_or_update_assessments_and_questions with force_update: #{force_update}"
    )

    assessment_multi =
      Multi.insert_or_update(
        Multi.new(),
        :assessment,
        insert_or_update_assessment_changeset(assessment_params, force_update)
      )

    if force_update and invalid_force_update(assessment_multi, questions_params) do
      Logger.error("Force update failed: Question count is different")
      {:error, "Question count is different"}
    else
      Logger.info("Processing questions for assessment")

      questions_params
      |> Enum.with_index(1)
      |> Enum.reduce(assessment_multi, fn {question_params, index}, multi ->
        Multi.run(multi, "question#{index}", fn _repo, %{assessment: %Assessment{id: id}} ->
          Logger.debug("Processing question #{index} for assessment #{id}")

          question =
            Question
            |> where([q], q.display_order == ^index and q.assessment_id == ^id)
            |> Repo.one()

          # the is_nil(question) check allows for force updating of brand new assessments
          if !force_update or is_nil(question) do
            Logger.info("Inserting new question at display_order #{index}")

            {status, new_question} =
              question_params
              |> Map.put(:display_order, index)
              |> build_question_changeset_for_assessment_id(id)
              |> Repo.insert()

            if status == :ok and new_question.type == :voting do
              Logger.info("Inserting voting entries for question #{new_question.id}")

              insert_voting(
                assessment_params.course_id,
                question_params.question.contest_number,
                new_question.id
              )
            else
              {status, new_question}
            end
          else
            Logger.info("Updating existing question at display_order #{index}")

            params =
              question_params
              |> Map.put_new(:max_xp, 0)
              |> Map.put(:display_order, index)

            if question_params.type != Atom.to_string(question.type) do
              Logger.error("Question type mismatch for question #{question.id}")

              {:error,
               create_invalid_changeset_with_error(
                 :question,
                 "Question types should remain the same"
               )}
            else
              question
              |> Question.changeset(params)
              |> Repo.update()
            end
          end
        end)
      end)
      |> Repo.transaction()
    end
  end

  # Function that checks if the force update is invalid. The force update is only invalid
  # if the new question count is different from the old question count.
  defp invalid_force_update(assessment_multi, questions_params) do
    Logger.info("Checking for invalid force update")

    assessment_id =
      (assessment_multi.operations
       |> List.first()
       |> elem(1)
       |> elem(1)).data.id

    if assessment_id do
      open_date = Repo.get(Assessment, assessment_id).open_at
      # check if assessment is already opened
      if Timex.compare(open_date, Timex.now()) >= 0 do
        Logger.info("Assessment #{assessment_id} is not yet open")
        false
      else
        existing_questions_count =
          Question
          |> where([q], q.assessment_id == ^assessment_id)
          |> Repo.all()
          |> Enum.count()

        new_questions_count = Enum.count(questions_params)

        Logger.info(
          "Existing questions count: #{existing_questions_count}, New questions count: #{new_questions_count}"
        )

        existing_questions_count != new_questions_count
      end
    else
      Logger.info("No assessment ID found in multi")
      false
    end
  end

  @spec insert_or_update_assessment_changeset(map(), boolean()) :: Ecto.Changeset.t()
  defp insert_or_update_assessment_changeset(
         params = %{number: number, course_id: course_id},
         force_update
       ) do
    Assessment
    |> where(number: ^number)
    |> where(course_id: ^course_id)
    |> Repo.one()
    |> case do
      nil ->
        Logger.info("Inserting new assessment")
        Assessment.changeset(%Assessment{}, params)

      %{id: assessment_id} = assessment ->
        Logger.info("Updating existing assessment #{assessment_id}")

        answers_exist =
          Answer
          |> join(:inner, [a], q in assoc(a, :question))
          |> join(:inner, [a, q], asst in assoc(q, :assessment))
          |> where([a, q, asst], asst.id == ^assessment_id)
          |> Repo.exists?()

        if answers_exist do
          Logger.info("Existing answers found for assessment #{assessment_id}")
        end

        # Maintain the same open/close date when updating an assessment
        params =
          params
          |> Map.delete(:open_at)
          |> Map.delete(:close_at)
          |> Map.delete(:is_published)

        cond do
          not answers_exist ->
            Logger.info("No existing answers found for assessment #{assessment_id}")

            Logger.info("Deleting all related submission_votes for assessment #{assessment_id}")
            # Delete all related submission_votes
            SubmissionVotes
            |> join(:inner, [sv, q], q in assoc(sv, :question))
            |> where([sv, q], q.assessment_id == ^assessment_id)
            |> Repo.delete_all()

            Logger.info("Deleting all related questions for assessment #{assessment_id}")
            # Delete all existing questions
            Question
            |> where(assessment_id: ^assessment_id)
            |> Repo.delete_all()

            Assessment.changeset(assessment, params)

          force_update ->
            Assessment.changeset(assessment, params)

          true ->
            # if the assessment has submissions, don't edit
            create_invalid_changeset_with_error(:assessment, "has submissions")
        end
    end
  end

  @spec build_question_changeset_for_assessment_id(map(), number() | String.t()) ::
          Ecto.Changeset.t()
  defp build_question_changeset_for_assessment_id(params, assessment_id)
       when is_ecto_id(assessment_id) do
    params_with_assessment_id = Map.put_new(params, :assessment_id, assessment_id)

    Question.changeset(%Question{}, params_with_assessment_id)
  end

  def reassign_voting(assessment_id, is_reassigning_voting) do
    Logger.info(
      "Reassigning voting for assessment #{assessment_id}, is_reassigning_voting: #{is_reassigning_voting}"
    )

    if is_reassigning_voting do
      if is_voting_published(assessment_id) do
        Logger.info("Deleting existing submissions for assessment #{assessment_id}")

        Submission
        |> where(assessment_id: ^assessment_id)
        |> delete_submission_association(assessment_id)

        Logger.info("Deleting all related submission_votes for assessment #{assessment_id}")

        Question
        |> where(assessment_id: ^assessment_id)
        |> Repo.all()
        |> Enum.each(fn q ->
          delete_submission_votes_association(q)
        end)
      end

      voting_assigned_question_ids =
        SubmissionVotes
        |> select([v], v.question_id)
        |> Repo.all()

      unpublished_voting_questions =
        Question
        |> where(type: :voting)
        |> where([q], q.id not in ^voting_assigned_question_ids)
        |> where(assessment_id: ^assessment_id)
        |> join(:inner, [q], asst in assoc(q, :assessment))
        |> select([q, asst], %{course_id: asst.course_id, question: q.question, id: q.id})
        |> Repo.all()

      Logger.info("Assigning voting for #{length(unpublished_voting_questions)} questions")

      for q <- unpublished_voting_questions do
        Logger.debug("Inserting voting for question #{q.id}")
        insert_voting(q.course_id, q.question["contest_number"], q.id)
      end

      {:ok, "voting assigned"}
    else
      Logger.info("No changes to voting for assessment #{assessment_id}")
      {:ok, "no change to voting"}
    end
  end

  defp is_voting_published(assessment_id) do
    Logger.info("Checking if voting is published for assessment #{assessment_id}")

    voting_assigned_question_ids =
      SubmissionVotes
      |> select([v], v.question_id)

    Question
    |> where(type: :voting)
    |> where(assessment_id: ^assessment_id)
    |> where([q], q.id in subquery(voting_assigned_question_ids))
    |> Repo.exists?() || false
  end

  def update_final_contest_entries do
    # 1435 = 1 day - 5 minutes
    if Log.log_execution("update_final_contest_entries", Duration.from_minutes(1435)) do
      Logger.info("Started update of contest entry pools")
      questions = fetch_unassigned_voting_questions()

      for q <- questions do
        insert_voting(q.course_id, q.question["contest_number"], q.question_id)
      end

      Logger.info("Successfully update contest entry pools")
    end
  end

  # fetch voting questions where entries have not been assigned
  def fetch_unassigned_voting_questions do
    Logger.info("Fetching unassigned voting questions")

    voting_assigned_question_ids =
      SubmissionVotes
      |> select([v], v.question_id)
      |> Repo.all()

    Logger.info("Found #{length(voting_assigned_question_ids)} voting assigned questions")

    valid_assessments =
      Assessment
      |> select([a], %{number: a.number, course_id: a.course_id})
      |> Repo.all()

    Logger.info("Found #{length(valid_assessments)} valid assessments")

    valid_questions =
      Question
      |> where(type: :voting)
      |> where([q], q.id not in ^voting_assigned_question_ids)
      |> join(:inner, [q], asst in assoc(q, :assessment))
      |> select([q, asst], %{course_id: asst.course_id, question: q.question, question_id: q.id})
      |> Repo.all()

    Logger.info("Found #{length(valid_questions)} valid questions")

    # fetch only voting where there is a corresponding contest
    Enum.filter(valid_questions, fn q ->
      Enum.any?(
        valid_assessments,
        fn a -> a.number == q.question["contest_number"] and a.course_id == q.course_id end
      )
    end)
  end

  @doc """
  Generates and assigns contest entries for users with given usernames.
  """
  def insert_voting(
        course_id,
        contest_number,
        question_id
      ) do
    Logger.info("Inserting voting for question #{question_id} in contest #{contest_number}")
    contest_assessment = Repo.get_by(Assessment, number: contest_number, course_id: course_id)

    if is_nil(contest_assessment) do
      Logger.error("Contest assessment not found")
      changeset = change(%Assessment{}, %{number: ""})

      error_changeset =
        Ecto.Changeset.add_error(
          changeset,
          :number,
          "invalid contest number"
        )

      {:error, error_changeset}
    else
      if Timex.compare(contest_assessment.close_at, Timex.now()) < 0 do
        Logger.info("Contest has closed for assessment #{contest_assessment.id}")
        compile_entries(course_id, contest_assessment, question_id)
      else
        Logger.info("Contest has not closed for assessment #{contest_assessment.id}")
        # contest has not closed, do nothing
        {:ok, nil}
      end
    end
  end

  def compile_entries(
        course_id,
        contest_assessment,
        question_id
      ) do
    Logger.info(
      "Compiling entries for question #{question_id} in contest #{contest_assessment.id}"
    )

    # Returns contest submission ids with answers that contain "return"
    contest_submission_ids =
      Submission
      |> join(:inner, [s], ans in assoc(s, :answers))
      |> join(:inner, [s, ans], cr in assoc(s, :student))
      |> where([s, ans, cr], cr.role == "student")
      |> where([s, _], s.assessment_id == ^contest_assessment.id and s.status == "submitted")
      |> where(
        [_, ans, cr],
        fragment(
          "?->>'code' like ?",
          ans.answer,
          "%return%"
        )
      )
      |> select([s, _ans], {s.student_id, s.id})
      |> Repo.all()
      |> Enum.into(%{})

    contest_submission_ids_length = Enum.count(contest_submission_ids)

    Logger.info(
      "Found #{contest_submission_ids_length} valid contest submissions with 'return' in their code"
    )

    voter_ids =
      CourseRegistration
      |> where(role: "student", course_id: ^course_id)
      |> select([cr], cr.id)
      |> Repo.all()

    Logger.info("Found #{length(voter_ids)} voter IDs")

    votes_per_user = min(contest_submission_ids_length, 10)

    votes_per_submission =
      if Enum.empty?(contest_submission_ids) do
        0
      else
        trunc(Float.ceil(votes_per_user * length(voter_ids) / contest_submission_ids_length))
      end

    Logger.info("Setting votes per submission to #{votes_per_submission}")

    submission_id_list =
      contest_submission_ids
      |> Enum.map(fn {_, s_id} -> s_id end)
      |> Enum.shuffle()
      |> List.duplicate(votes_per_submission)
      |> List.flatten()

    {_submission_map, submission_votes_changesets} =
      voter_ids
      |> Enum.reduce({submission_id_list, []}, fn voter_id, acc ->
        {submission_list, submission_votes} = acc

        user_contest_submission_id = Map.get(contest_submission_ids, voter_id)

        {votes, rest} =
          submission_list
          |> Enum.reduce_while({MapSet.new(), submission_list}, fn s_id, acc ->
            {user_votes, submissions} = acc

            max_votes =
              if votes_per_user == contest_submission_ids_length and
                   not is_nil(user_contest_submission_id) do
                # no. of submssions is less than 10. Unable to find
                votes_per_user - 1
              else
                votes_per_user
              end

            if MapSet.size(user_votes) < max_votes do
              if s_id != user_contest_submission_id and not MapSet.member?(user_votes, s_id) do
                new_user_votes = MapSet.put(user_votes, s_id)
                new_submissions = List.delete(submissions, s_id)
                {:cont, {new_user_votes, new_submissions}}
              else
                {:cont, {user_votes, submissions}}
              end
            else
              {:halt, acc}
            end
          end)

        votes = MapSet.to_list(votes)

        new_submission_votes =
          votes
          |> Enum.map(fn s_id ->
            %SubmissionVotes{
              voter_id: voter_id,
              submission_id: s_id,
              question_id: question_id
            }
          end)
          |> Enum.concat(submission_votes)

        {rest, new_submission_votes}
      end)

    submission_votes_changesets
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {changeset, index}, multi ->
      Multi.insert(multi, Integer.to_string(index), changeset)
    end)
    |> Repo.transaction()
  end

  def update_assessment(id, params) when is_ecto_id(id) do
    Logger.info("Updating assessment ID #{id} with params: #{inspect(params)}")

    simple_update(
      Assessment,
      id,
      using: &Assessment.changeset/2,
      params: params
    )
  end

  def update_question(id, params) when is_ecto_id(id) do
    Logger.info("Updating question ID #{id} with params: #{inspect(params)}")

    simple_update(
      Question,
      id,
      using: &Question.changeset/2,
      params: params
    )
  end

  def publish_assessment(id) when is_ecto_id(id) do
    Logger.info("Publishing assessment: #{id}")
    update_assessment(id, %{is_published: true})
  end

  def create_question_for_assessment(params, assessment_id) when is_ecto_id(assessment_id) do
    Logger.info(
      "Creating question for assessment ID #{assessment_id} with params: #{inspect(params)}"
    )

    assessment =
      Assessment
      |> where(id: ^assessment_id)
      |> join(:left, [a], q in assoc(a, :questions))
      |> preload([_, q], questions: q)
      |> Repo.one()

    if assessment do
      params_with_assessment_id = Map.put_new(params, :assessment_id, assessment.id)

      result =
        %Question{}
        |> Question.changeset(params_with_assessment_id)
        |> put_display_order(assessment.questions)
        |> Repo.insert()

      case result do
        {:ok, _} ->
          Logger.info("Successfully created question for assessment")

        {:error, changeset} ->
          Logger.error(
            "Failed to create question for assessment: #{full_error_messages(changeset)}"
          )
      end

      result
    else
      Logger.error("Assessment not found")
      {:error, "Assessment not found"}
    end
  end

  def get_question(id) when is_ecto_id(id) do
    Logger.info("Fetching question #{id}")

    Question
    |> where(id: ^id)
    |> join(:inner, [q], assessment in assoc(q, :assessment))
    |> preload([_, a], assessment: a)
    |> Repo.one()
  end

  def delete_question(id) when is_ecto_id(id) do
    Logger.info("Deleting question #{id}")

    question = Repo.get(Question, id)
    Repo.delete(question)
  end

  def get_contest_voting_question(assessment_id) do
    Logger.info("Fetching contest voting question for assessment #{assessment_id}")

    Question
    |> where(type: :voting)
    |> where(assessment_id: ^assessment_id)
    |> Repo.one()
  end

  @doc """
  Public internal api to submit new answers for a question. Possible return values are:
  `{:ok, nil}` -> success
  `{:error, error}` -> failed. `error` is in the format of `{http_response_code, error message}`

  Note: In the event of `find_or_create_submission` failing due to a race condition, error will be:
   `{:bad_request, "Missing or invalid parameter(s)"}`

  """
  def answer_question(
        question = %Question{},
        cr = %CourseRegistration{id: cr_id},
        raw_answer,
        force_submit
      ) do
    Logger.info("Attempting to answer question #{question.id} for user #{cr_id}")

    with {:ok, _team} <- find_team(question.assessment.id, cr_id),
         {:ok, submission} <- find_or_create_submission(cr, question.assessment),
         {:status, true} <- {:status, force_submit or submission.status != :submitted},
         {:ok, _answer} <- insert_or_update_answer(submission, question, raw_answer, cr_id) do
      Logger.info("Successfully answered question #{question.id} for user #{cr_id}")
      update_submission_status_router(submission, question)

      {:ok, nil}
    else
      {:status, _} ->
        Logger.error("Failed to answer question #{question.id} - submission already finalized")
        {:error, {:forbidden, "Assessment submission already finalised"}}

      {:error, :race_condition} ->
        Logger.error("Race condition encountered while answering question #{question.id}")
        {:error, {:internal_server_error, "Please try again later."}}

      {:error, :team_not_found} ->
        Logger.error("Team not found for question #{question.id} and user #{cr_id}")
        {:error, {:bad_request, "Your existing Team has been deleted!"}}

      {:error, :invalid_vote} ->
        Logger.error("Invalid vote for question #{question.id} by user #{cr_id}")
        {:error, {:bad_request, "Invalid vote! Vote is not saved."}}

      _ ->
        Logger.error("Failed to answer question #{question.id} - invalid parameters")
        {:error, {:bad_request, "Missing or invalid parameter(s)"}}
    end
  end

  def is_team_assessment?(assessment_id) when is_ecto_id(assessment_id) do
    Logger.info("Checking if assessment #{assessment_id} is a team assessment")

    max_team_size =
      Assessment
      |> where(id: ^assessment_id)
      |> select([a], a.max_team_size)
      |> Repo.one()

    Logger.info("Assessment #{assessment_id} has max team size #{max_team_size}")
    max_team_size > 1
  end

  defp find_teams(cr_id) when is_ecto_id(cr_id) do
    Logger.info("Finding teams for user #{cr_id}")

    teams =
      Team
      |> join(:inner, [t], tm in assoc(t, :team_members))
      |> where([_, tm], tm.student_id == ^cr_id)
      |> Repo.all()

    Logger.info("Found #{length(teams)} teams for user #{cr_id}")
    teams
  end

  defp find_team(assessment_id, cr_id)
       when is_ecto_id(assessment_id) and is_ecto_id(cr_id) do
    Logger.info("Finding team for assessment #{assessment_id} and user #{cr_id}")

    query =
      from(t in Team,
        where: t.assessment_id == ^assessment_id,
        join: tm in assoc(t, :team_members),
        where: tm.student_id == ^cr_id,
        limit: 1
      )

    if is_team_assessment?(assessment_id) do
      case Repo.one(query) do
        nil ->
          Logger.error("Team not found for assessment #{assessment_id} and user #{cr_id}")
          {:error, :team_not_found}

        team ->
          Logger.info("Found team #{team.id} for assessment #{assessment_id} and user #{cr_id}")
          {:ok, team}
      end
    else
      # team is nil for individual assessments
      Logger.info("Assessment #{assessment_id} is not a team assessment")
      {:ok, nil}
    end
  end

  def get_submission(assessment_id, %CourseRegistration{id: cr_id})
      when is_ecto_id(assessment_id) do
    Logger.info("Getting submission for assessment #{assessment_id} and user #{cr_id}")
    {:ok, team} = find_team(assessment_id, cr_id)

    case team do
      %Team{} ->
        Logger.info("Getting team submission for team #{team.id} of user #{cr_id}")

        Submission
        |> where(assessment_id: ^assessment_id)
        |> where(team_id: ^team.id)
        |> join(:inner, [s], a in assoc(s, :assessment))
        |> preload([_, a], assessment: a)
        |> Repo.one()

      nil ->
        Logger.info("Getting individual submission for user #{cr_id}")

        Submission
        |> where(assessment_id: ^assessment_id)
        |> where(student_id: ^cr_id)
        |> join(:inner, [s], a in assoc(s, :assessment))
        |> preload([_, a], assessment: a)
        |> Repo.one()
    end
  end

  def get_submission_by_id(submission_id) when is_ecto_id(submission_id) do
    Logger.info("Getting submission with ID #{submission_id}")

    Submission
    |> where(id: ^submission_id)
    |> join(:inner, [s], a in assoc(s, :assessment))
    |> preload([_, a], assessment: a)
    |> Repo.one()
  end

  def finalise_submission(submission = %Submission{}) do
    Logger.info(
      "Finalizing submission #{submission.id} for assessment #{submission.assessment_id}"
    )

    with {:status, :attempted} <- {:status, submission.status},
         {:ok, updated_submission} <- update_submission_status(submission) do
      # Couple with update_submission_status and update_xp_bonus to ensure notification is sent
      submission = Repo.preload(submission, assessment: [:config])

      if submission.assessment.config.is_manually_graded do
        Notifications.write_notification_when_student_submits(submission)
      end

      # Send email notification to avenger
      %{notification_type: "assessment_submission", submission_id: updated_submission.id}
      |> Cadet.Workers.NotificationWorker.new()
      |> Oban.insert()

      # Begin autograding job
      GradingJob.force_grade_individual_submission(updated_submission)
      update_xp_bonus(updated_submission)

      Logger.info("Successfully finalized submission #{submission.id}")
      {:ok, nil}
    else
      {:status, :attempting} ->
        Logger.error(
          "Cannot finalize submission #{submission.id} - some questions have not been attempted"
        )

        {:error, {:bad_request, "Some questions have not been attempted"}}

      {:status, :submitted} ->
        Logger.error(
          "Cannot finalize submission #{submission.id} - assessment has already been submitted"
        )

        {:error, {:forbidden, "Assessment has already been submitted"}}

      _ ->
        Logger.error("Failed to finalize submission #{submission.id} - unknown error")
        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  def unsubmit_submission(
        submission_id,
        cr = %CourseRegistration{id: course_reg_id, role: role}
      )
      when is_ecto_id(submission_id) do
    Logger.info("Unsubmitting submission #{submission_id} for user #{course_reg_id}")

    submission =
      Submission
      |> join(:inner, [s], a in assoc(s, :assessment))
      |> preload([_, a], assessment: a)
      |> Repo.get(submission_id)

    # allows staff to unsubmit own assessment
    bypass = role in @bypass_closed_roles and submission.student_id == course_reg_id
    Logger.info("Bypass restrictions: #{bypass}")

    with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
         {:is_open?, true} <- {:is_open?, bypass or is_open?(submission.assessment)},
         {:status, :submitted} <- {:status, submission.status},
         {:allowed_to_unsubmit?, true} <-
           {:allowed_to_unsubmit?,
            role == :admin or bypass or is_nil(submission.student_id) or
              Cadet.Accounts.Query.avenger_of?(cr, submission.student_id)},
         {:is_grading_published?, false} <-
           {:is_grading_published?, submission.is_grading_published} do
      Logger.info("All checks passed for unsubmitting submission #{submission_id}")

      Multi.new()
      |> Multi.run(
        :rollback_submission,
        fn _repo, _ ->
          Logger.info("Rolling back submission #{submission_id}")

          submission
          |> Submission.changeset(%{
            status: :attempted,
            xp_bonus: 0,
            unsubmitted_by_id: course_reg_id,
            unsubmitted_at: Timex.now()
          })
          |> Repo.update()
        end
      )
      |> Multi.run(:rollback_answers, fn _repo, _ ->
        Logger.info("Rolling back answers for submission #{submission_id}")

        Answer
        |> join(:inner, [a], q in assoc(a, :question))
        |> join(:inner, [a, _], s in assoc(a, :submission))
        |> preload([_, q, s], question: q, submission: s)
        |> where(submission_id: ^submission.id)
        |> Repo.all()
        |> Enum.reduce_while({:ok, nil}, fn answer, acc ->
          case acc do
            {:error, _} ->
              Logger.error(
                "Error encountered while rolling back answers for submission #{submission_id}"
              )

              {:halt, acc}

            {:ok, _} ->
              Logger.info("Rolling back answer #{answer.id} for submission #{submission_id}")

              {:cont,
               answer
               |> Answer.grading_changeset(%{
                 xp: 0,
                 xp_adjustment: 0,
                 autograding_status: :none,
                 autograding_results: []
               })
               |> Repo.update()}
          end
        end)
      end)
      |> Repo.transaction()

      case submission.student_id do
        # Team submission, handle notifications for team members
        nil ->
          Logger.info("Handling unsubmit notifications for team submission #{submission.id}")
          team = Repo.get(Team, submission.team_id)

          query =
            from(t in Team,
              join: tm in TeamMember,
              on: t.id == tm.team_id,
              join: cr in CourseRegistration,
              on: tm.student_id == cr.id,
              where: t.id == ^team.id,
              select: cr.id
            )

          team_members = Repo.all(query)

          Enum.each(team_members, fn tm_id ->
            Logger.info("Sending unsubmit notification to team member #{tm_id}")

            Notifications.handle_unsubmit_notifications(
              submission.assessment.id,
              Repo.get(CourseRegistration, tm_id)
            )
          end)

        student_id ->
          Logger.info(
            "Handling unsubmit notifications for individual submission #{submission.id}"
          )

          Notifications.handle_unsubmit_notifications(
            submission.assessment.id,
            Repo.get(CourseRegistration, student_id)
          )
      end

      Logger.info("Removing grading notifications for submission #{submission.id}")

      # Remove grading notifications for submissions
      Notification
      |> where(submission_id: ^submission_id, type: :submitted)
      |> select([n], n.id)
      |> Repo.all()
      |> Notifications.acknowledge(cr)

      Logger.info("Successfully unsubmitting submission #{submission_id}")
      {:ok, nil}
    else
      {:submission_found?, false} ->
        Logger.error("Submission #{submission_id} not found")
        {:error, {:not_found, "Submission not found"}}

      {:is_open?, false} ->
        Logger.error("Assessment for submission #{submission_id} is not open")
        {:error, {:forbidden, "Assessment not open"}}

      {:status, :attempting} ->
        Logger.error("Submission #{submission_id} is still attempting")
        {:error, {:bad_request, "Some questions have not been attempted"}}

      {:status, :attempted} ->
        Logger.error("Submission #{submission_id} has already been attempted")
        {:error, {:bad_request, "Assessment has not been submitted"}}

      {:allowed_to_unsubmit?, false} ->
        Logger.error(
          "User #{course_reg_id} is not allowed to unsubmit submission #{submission_id}"
        )

        {:error, {:forbidden, "Only Avenger of student or Admin is permitted to unsubmit"}}

      {:is_grading_published?, true} ->
        Logger.error("Grading for submission #{submission_id} has already been published")
        {:error, {:forbidden, "Grading has not been unpublished"}}

      _ ->
        Logger.error("An unknown error occurred while unsubmitting submission #{submission_id}")
        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  defp can_publish?(submission_id, cr = %CourseRegistration{id: course_reg_id, role: role}) do
    Logger.info(
      "Checking if submission #{submission_id} can be published by user #{course_reg_id}"
    )

    submission =
      Submission
      |> join(:inner, [s], a in assoc(s, :assessment))
      |> join(:inner, [_, a], c in assoc(a, :config))
      |> preload([_, a, c], assessment: {a, config: c})
      |> Repo.get(submission_id)

    Logger.debug("Fetched submission: #{inspect(submission)}")

    # allows staff to unpublish own assessment
    bypass = role in @bypass_closed_roles and submission.student_id == course_reg_id
    Logger.info("Bypass restrictions: #{bypass}")

    # assumption: if team assessment, all team members are under the same avenger
    effective_student_id =
      if is_nil(submission.student_id) do
        Logger.info("Fetching first team member for team submission #{submission.team_id}")
        Teams.get_first_member(submission.team_id).student_id
      else
        submission.student_id
      end

    Logger.info("Effective student ID: #{effective_student_id}")

    with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
         {:status, :submitted} <- {:status, submission.status},
         {:is_manually_graded?, true} <-
           {:is_manually_graded?, submission.assessment.config.is_manually_graded},
         {:fully_graded?, true} <- {:fully_graded?, is_fully_graded?(submission_id)},
         {:allowed_to_publish?, true} <-
           {:allowed_to_publish?,
            role == :admin or bypass or
              Cadet.Accounts.Query.avenger_of?(cr, effective_student_id)} do
      Logger.info("All checks passed!")
      {:ok, submission}
    else
      err ->
        case err do
          {:submission_found?, false} ->
            Logger.error("Submission #{submission_id} not found")

          {:status, _} ->
            Logger.error("Submission #{submission_id} is not in a submitted state")

          {:is_manually_graded?, false} ->
            Logger.error("Submission #{submission_id} is not manually graded")

          {:fully_graded?, false} ->
            Logger.error("Submission #{submission_id} is not fully graded")

          {:allowed_to_publish?, false} ->
            Logger.error(
              "User #{course_reg_id} is not allowed to publish submission #{submission_id}"
            )

          error ->
            Logger.error("Unknown error occurred while publishing submission: #{inspect(error)}")
        end

        err
    end
  end

  @doc """
    Unpublishes grading for a submission and send notification to student.
    Requires admin or staff who is group leader of student.

    Only manually graded assessments can be individually unpublished. We can only
    unpublish all submissions for auto-graded assessments.

    Returns `{:ok, nil}` on success, otherwise `{:error, {status, message}}`.
  """
  def unpublish_grading(submission_id, cr = %CourseRegistration{})
      when is_ecto_id(submission_id) do
    Logger.info("Attempting to unpublish grading for submission #{submission_id}")

    case can_publish?(submission_id, cr) do
      {:ok, submission} ->
        Logger.info("Unpublishing grading for submission #{submission_id}")

        submission
        |> Submission.changeset(%{is_grading_published: false})
        |> Repo.update()

        # assumption: if team assessment, all team members are under the same avenger
        effective_student_id =
          if is_nil(submission.student_id) do
            Logger.info("Fetching first team member for team submission #{submission.team_id}")
            Teams.get_first_member(submission.team_id).student_id
          else
            submission.student_id
          end

        Logger.info(
          "Sending unpublish grades notification for assessment #{submission.assessment.id} to student #{effective_student_id}"
        )

        Notifications.handle_unpublish_grades_notifications(
          submission.assessment.id,
          Repo.get(CourseRegistration, effective_student_id)
        )

        Logger.info("Successfully unpublished grading for submission #{submission_id}")
        {:ok, nil}

      {:submission_found?, false} ->
        Logger.error("Submission #{submission_id} not found")
        {:error, {:not_found, "Submission not found"}}

      {:allowed_to_publish?, false} ->
        Logger.error(
          "User #{cr.id} is not allowed to unpublish grading for submission #{submission_id}"
        )

        {:error,
         {:forbidden, "Only Avenger of student or Admin is permitted to unpublish grading"}}

      {:is_manually_graded?, false} ->
        Logger.error(
          "Submission #{submission_id} is not manually graded and cannot be unpublished"
        )

        {:error,
         {:bad_request, "Only manually graded assessments can be individually unpublished"}}

      err ->
        Logger.error(
          "Unknown error occurred while unpublishing grading for submission #{submission_id}: #{inspect(err)}"
        )

        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  @doc """
    Publishes grading for a submission and send notification to student.
    Requires admin or staff who is group leader of student and all answers to be graded.

    Only manually graded assessments can be individually published. We can only
    publish all submissions for auto-graded assessments.

    Returns `{:ok, nil}` on success, otherwise `{:error, {status, message}}`.
  """
  def publish_grading(submission_id, cr = %CourseRegistration{})
      when is_ecto_id(submission_id) do
    Logger.info("Attempting to publish grading for submission #{submission_id}")

    case can_publish?(submission_id, cr) do
      {:ok, submission} ->
        Logger.info("Publishing grading for submission #{submission_id}")

        submission
        |> Submission.changeset(%{is_grading_published: true})
        |> Repo.update()

        Logger.info("Updating XP bonus for submission #{submission_id}")
        update_xp_bonus(submission)

        Logger.info("Writing notification for published grading for submission #{submission_id}")

        Notifications.write_notification_when_published(
          submission.id,
          :published_grading
        )

        Logger.info("Acknowledging notifications for submission #{submission_id}")

        Notification
        |> where(submission_id: ^submission.id, type: :submitted)
        |> select([n], n.id)
        |> Repo.all()
        |> Notifications.acknowledge(cr)

        Logger.info("Successfully published grading for submission #{submission_id}")
        {:ok, nil}

      {:submission_found?, false} ->
        Logger.error("Submission #{submission_id} not found")
        {:error, {:not_found, "Submission not found"}}

      {:status, :attempting} ->
        Logger.error("Submission #{submission_id} is still attempting")
        {:error, {:bad_request, "Some questions have not been attempted"}}

      {:status, :attempted} ->
        Logger.error("Submission #{submission_id} has not been submitted")
        {:error, {:bad_request, "Assessment has not been submitted"}}

      {:allowed_to_publish?, false} ->
        Logger.error(
          "User #{cr.id} is not allowed to publish grading for submission #{submission_id}"
        )

        {:error, {:forbidden, "Only Avenger of student or Admin is permitted to publish grading"}}

      {:is_manually_graded?, false} ->
        Logger.error("Submission #{submission_id} is not manually graded and cannot be published")
        {:error, {:bad_request, "Only manually graded assessments can be individually published"}}

      {:fully_graded?, false} ->
        Logger.error("Some answers in submission #{submission_id} are not graded")
        {:error, {:bad_request, "Some answers are not graded"}}

      err ->
        Logger.error(
          "Unknown error occurred while publishing grading for submission #{submission_id}: #{inspect(err)}"
        )

        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  @doc """
    Publishes grading for a submission and send notification to student.
    This function is used by the auto-grading system to publish grading. Bypasses Course Reg checks.

    Returns `{:ok, nil}` on success, otherwise `{:error, {status, message}}`.
  """
  def publish_grading(submission_id)
      when is_ecto_id(submission_id) do
    Logger.info("Attempting to publish grading for submission #{submission_id}")

    submission =
      Submission
      |> join(:inner, [s], a in assoc(s, :assessment))
      |> preload([_, a], assessment: a)
      |> Repo.get(submission_id)

    with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
         {:status, :submitted} <- {:status, submission.status} do
      Logger.info("Publishing grading for submission #{submission_id}")

      submission
      |> Submission.changeset(%{is_grading_published: true})
      |> Repo.update()

      Logger.info("Writing notification for published grading for submission #{submission_id}")

      Notifications.write_notification_when_published(
        submission.id,
        :published_grading
      )

      Logger.info("Successfully published grading for submission #{submission_id}")
      {:ok, nil}
    else
      {:submission_found?, false} ->
        Logger.error("Submission #{submission_id} not found")
        {:error, {:not_found, "Submission not found"}}

      {:status, :attempting} ->
        Logger.error("Student is still attempting submission #{submission_id}")
        {:error, {:bad_request, "Some questions have not been attempted"}}

      {:status, :attempted} ->
        Logger.error("Submission #{submission_id} has not been submitted")
        {:error, {:bad_request, "Assessment has not been submitted"}}

      err ->
        Logger.error(
          "Unknown error occurred while publishing grading for submission #{submission_id}: #{inspect(err)}"
        )

        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  @doc """
    Publishes grading for all graded submissions for an assessment and sends notifications to students.
    Requires admin.

    Returns `{:ok, nil}` on success, otherwise `{:error, {status, message}}`.
  """
  def publish_all_graded(publisher = %CourseRegistration{}, assessment_id) do
    Logger.info("Attempting to publish all graded submissions for assessment #{assessment_id}")

    if publisher.role == :admin do
      Logger.info("User #{publisher.id} is an admin, proceeding with publishing")

      answers_query =
        Answer
        |> group_by([ans], ans.submission_id)
        |> select([ans], %{
          submission_id: ans.submission_id,
          graded_count: filter(count(ans.id), not is_nil(ans.grader_id)),
          autograded_count: filter(count(ans.id), ans.autograding_status == :success)
        })

      question_query =
        Question
        |> group_by([q], q.assessment_id)
        |> join(:inner, [q], a in Assessment, on: q.assessment_id == a.id)
        |> select([q, a], %{
          assessment_id: q.assessment_id,
          question_count: count(q.id)
        })

      submission_query =
        Submission
        |> join(:inner, [s], ans in subquery(answers_query), on: ans.submission_id == s.id)
        |> join(:inner, [s, ans], asst in subquery(question_query),
          on: s.assessment_id == asst.assessment_id
        )
        |> join(:inner, [s, ans, asst], cr in CourseRegistration, on: s.student_id == cr.id)
        |> where([s, ans, asst, cr], cr.course_id == ^publisher.course_id)
        |> where(
          [s, ans, asst, cr],
          asst.question_count == ans.graded_count or asst.question_count == ans.autograded_count
        )
        |> where([s, ans, asst, cr], s.is_grading_published == false)
        |> where([s, ans, asst, cr], s.assessment_id == ^assessment_id)
        |> select([s, ans, asst, cr], %{
          id: s.id
        })

      Logger.info("Fetching submissions eligible for publishing")
      submissions = Repo.all(submission_query)

      Logger.info("Updating submissions to set grading as published")
      Repo.update_all(submission_query, set: [is_grading_published: true])

      Logger.info("Sending notifications for published submissions")

      Enum.each(submissions, fn submission ->
        Notifications.write_notification_when_published(
          submission.id,
          :published_grading
        )

        Logger.info("Notification sent for submission #{submission.id}")
      end)

      Logger.info("Successfully published all graded submissions for assessment #{assessment_id}")
      {:ok, nil}
    else
      Logger.error("User #{publisher.id} is not an admin, cannot publish all grades")
      {:error, {:forbidden, "Only Admin is permitted to publish all grades"}}
    end
  end

  @doc """
     Unpublishes grading for all submissions with grades published for an assessment and sends notifications to students.
     Requires admin role.

     Returns `{:ok, nil}` on success, otherwise `{:error, {status, message}}`.
  """

  def unpublish_all(publisher = %CourseRegistration{}, assessment_id) do
    Logger.info("Attempting to unpublish all submissions for assessment #{assessment_id}")

    if publisher.role == :admin do
      Logger.info("User #{publisher.id} is an admin, proceeding with unpublishing")

      submission_query =
        Submission
        |> join(:inner, [s], cr in CourseRegistration, on: s.student_id == cr.id)
        |> where([s, cr], cr.course_id == ^publisher.course_id)
        |> where([s, cr], s.is_grading_published == true)
        |> where([s, cr], s.assessment_id == ^assessment_id)
        |> select([s, cr], %{
          id: s.id,
          student_id: cr.id
        })

      Logger.info("Fetching submissions eligible for unpublishing")
      submissions = Repo.all(submission_query)

      Logger.info("Unpublishing submissions for assessment #{assessment_id}")
      Repo.update_all(submission_query, set: [is_grading_published: false])

      Logger.info("Sending notifications for unpublished submissions")

      Enum.each(submissions, fn submission ->
        Notifications.handle_unpublish_grades_notifications(
          assessment_id,
          Repo.get(CourseRegistration, submission.student_id)
        )
      end)

      {:ok, nil}
    else
      Logger.error("User #{publisher.id} is not an admin, cannot unpublish all grades")
      {:error, {:forbidden, "Only Admin is permitted to unpublish all grades"}}
    end
  end

  @spec update_submission_status(Submission.t()) ::
          {:ok, Submission.t()} | {:error, Ecto.Changeset.t()}
  defp update_submission_status(submission = %Submission{}) do
    Logger.info("Updating submission status for submission #{submission.id}")

    submission
    |> Submission.changeset(%{status: :submitted, submitted_at: Timex.now()})
    |> Repo.update()
  end

  @spec update_xp_bonus(Submission.t()) ::
          {:ok, Submission.t()} | {:error, Ecto.Changeset.t()}
  # TODO: Should destructure and pattern match on the function
  defp update_xp_bonus(submission = %Submission{id: submission_id}) do
    Logger.info("Updating XP bonus for submission #{submission_id}")
    # to ensure backwards compatibility
    if submission.xp_bonus == 0 do
      assessment = submission.assessment
      assessment_conifg = Repo.get_by(AssessmentConfig, id: assessment.config_id)

      max_bonus_xp = assessment_conifg.early_submission_xp
      early_hours = assessment_conifg.hours_before_early_xp_decay

      ans_xp =
        Answer
        |> where(submission_id: ^submission_id)
        |> order_by(:question_id)
        |> select([a], %{
          total_xp: a.xp + a.xp_adjustment
        })

      total =
        ans_xp
        |> subquery
        |> select([a], %{
          total_xp: coalesce(sum(a.total_xp), 0)
        })
        |> Repo.one()

      cur_time =
        if submission.submitted_at == nil do
          Timex.now()
        else
          submission.submitted_at
        end

      xp_bonus =
        if total.total_xp <= 0 do
          0
        else
          if Timex.before?(cur_time, Timex.shift(assessment.open_at, hours: early_hours)) do
            max_bonus_xp
          else
            # This logic interpolates from max bonus at early hour to 0 bonus at close time
            decaying_hours =
              Timex.diff(assessment.close_at, assessment.open_at, :hours) - early_hours

            remaining_hours = Enum.max([0, Timex.diff(assessment.close_at, cur_time, :hours)])
            proportion = if(decaying_hours > 0, do: remaining_hours / decaying_hours, else: 1)
            bonus_xp = round(max_bonus_xp * proportion)
            Enum.max([0, bonus_xp])
          end
        end

      Logger.info("XP bonus updated for submission #{submission_id}")

      submission
      |> Submission.changeset(%{xp_bonus: xp_bonus})
      |> Repo.update()
    end
  end

  defp update_submission_status_router(submission = %Submission{}, question = %Question{}) do
    Logger.info(
      "Updating submission status for submission #{submission.id} and question #{question.id}"
    )

    case question.type do
      :voting -> update_contest_voting_submission_status(submission, question)
      :mcq -> update_submission_status(submission, question.assessment)
      :programming -> update_submission_status(submission, question.assessment)
    end
  end

  defp update_submission_status(submission = %Submission{}, assessment = %Assessment{}) do
    Logger.info(
      "Updating submission status for submission #{submission.id} and assessment #{assessment.id}"
    )

    model_assoc_count = fn model, assoc, id ->
      model
      |> where(id: ^id)
      |> join(:inner, [m], a in assoc(m, ^assoc))
      |> select([_, a], count(a.id))
      |> Repo.one()
    end

    Multi.new()
    |> Multi.run(:assessment, fn _repo, _ ->
      {:ok, model_assoc_count.(Assessment, :questions, assessment.id)}
    end)
    |> Multi.run(:submission, fn _repo, _ ->
      {:ok, model_assoc_count.(Submission, :answers, submission.id)}
    end)
    |> Multi.run(:update, fn _repo, %{submission: s_count, assessment: a_count} ->
      if s_count == a_count do
        submission |> Submission.changeset(%{status: :attempted}) |> Repo.update()
      else
        {:ok, nil}
      end
    end)
    |> Repo.transaction()
  end

  defp update_contest_voting_submission_status(submission = %Submission{}, question = %Question{}) do
    Logger.info(
      "Updating contest voting submission status for submission #{submission.id} and question #{question.id}"
    )

    has_nil_entries =
      SubmissionVotes
      |> where(question_id: ^question.id)
      |> where(voter_id: ^submission.student_id)
      |> where([sv], is_nil(sv.score))
      |> Repo.exists?()

    unless has_nil_entries do
      submission |> Submission.changeset(%{status: :attempted}) |> Repo.update()
    end
  end

  defp load_contest_voting_entries(
         questions,
         %CourseRegistration{role: role, course_id: course_id, id: voter_id},
         assessment,
         visible_entries
       ) do
    Logger.info("Loading contest voting entries for assessment #{assessment.id}")

    Enum.map(
      questions,
      fn q ->
        if q.type == :voting do
          submission_votes = all_submission_votes_by_question_id_and_voter_id(q.id, voter_id)
          # fetch top 10 contest voting entries with the contest question id
          question_id = fetch_associated_contest_question_id(course_id, q)

          # fetch top 10 contest coting entries with contest question id based on popular score
          popular_results =
            if is_nil(question_id) do
              []
            else
              if leaderboard_open?(assessment, q) or role in @open_all_assessment_roles do
                fetch_top_popular_score_answers(question_id, visible_entries)
              else
                []
              end
            end

          leaderboard_results =
            if is_nil(question_id) do
              []
            else
              if leaderboard_open?(assessment, q) or role in @open_all_assessment_roles do
                fetch_top_relative_score_answers(question_id, visible_entries)
              else
                []
              end
            end

          # populate entries to vote for and leaderboard data into the question
          voting_question =
            q.question
            |> Map.put(:contest_entries, submission_votes)
            |> Map.put(
              :contest_leaderboard,
              leaderboard_results
            )
            |> Map.put(
              :popular_leaderboard,
              popular_results
            )

          Map.put(q, :question, voting_question)
        else
          q
        end
      end
    )
  end

  defp all_submission_votes_by_question_id_and_voter_id(question_id, voter_id) do
    Logger.info("Fetching all submission votes for question #{question_id} and voter #{voter_id}")

    SubmissionVotes
    |> where([v], v.voter_id == ^voter_id and v.question_id == ^question_id)
    |> join(:inner, [v], s in assoc(v, :submission))
    |> join(:inner, [v, s], a in assoc(s, :answers))
    |> select([v, s, a], %{submission_id: v.submission_id, answer: a.answer, score: v.score})
    |> Repo.all()
  end

  # Finds the contest_question_id associated with the given voting_question id
  def fetch_associated_contest_question_id(course_id, voting_question) do
    contest_number = voting_question.question["contest_number"]

    if is_nil(contest_number) do
      nil
    else
      Assessment
      |> where(number: ^contest_number, course_id: ^course_id)
      |> join(:inner, [a], q in assoc(a, :questions))
      |> order_by([a, q], q.display_order)
      |> select([a, q], q.id)
      |> Repo.one()
    end
  end

  defp leaderboard_open?(assessment, voting_question) do
    Timex.before?(
      Timex.shift(assessment.close_at, hours: voting_question.question["reveal_hours"]),
      Timex.now()
    )
  end

  def fetch_contest_voting_assesment_id(assessment_id) do
    contest_number =
      Assessment
      |> where(id: ^assessment_id)
      |> select([a], a.number)
      |> Repo.one()

    if is_nil(contest_number) do
      nil
    else
      Assessment
      |> join(:inner, [a], q in assoc(a, :questions))
      |> where([a, q], q.question["contest_number"] == ^contest_number)
      |> select([a], a.id)
      |> Repo.one()
    end
  end

  @doc """
  Fetches all contests for the course id where the voting assessment has been published

  Used for contest leaderboard dropdown fetching
  """
  def fetch_all_contests(course_id) do
    Logger.info("Fetching all contests for course #{course_id}")

    contest_numbers =
      Question
      |> where(type: :voting)
      |> select([q], q.question["contest_number"])
      |> Repo.all()
      |> Enum.reject(&is_nil/1)

    if contest_numbers == [] do
      []
    else
      Assessment
      |> where([a], a.number in ^contest_numbers and a.course_id == ^course_id)
      |> join(:inner, [a], ac in AssessmentConfig, on: a.config_id == ac.id)
      |> where([a, ac], ac.type == "Contests")
      |> select([a], %{contest_id: a.id, title: a.title, published: a.is_published})
      |> Repo.all()
    end
  end

  @doc """
  Fetches top answers for the given question, based on the contest relative_score

  Used for contest leaderboard fetching
  """
  def fetch_top_relative_score_answers(question_id, number_of_answers) do
    Logger.info("Fetching top relative score answers for question #{question_id}")

    subquery =
      Answer
      |> where(question_id: ^question_id)
      |> where(
        [a],
        fragment(
          "?->>'code' like ?",
          a.answer,
          "%return%"
        )
      )
      |> order_by(desc: :relative_score)
      |> join(:left, [a], s in assoc(a, :submission))
      |> join(:left, [a, s], student in assoc(s, :student))
      |> join(:inner, [a, s, student], student_user in assoc(student, :user))
      |> where([a, s, student], student.role == "student")
      |> select([a, s, student, student_user], %{
        submission_id: a.submission_id,
        answer: a.answer,
        relative_score: a.relative_score,
        student_name: student_user.name,
        student_username: student_user.username,
        rank: fragment("RANK() OVER (ORDER BY ? DESC)", a.relative_score)
      })

    final_query =
      from(r in subquery(subquery),
        where: r.rank <= ^number_of_answers
      )

    Repo.all(final_query)
  end

  @doc """
  Fetches top answers for the given question, based on the contest popular_score

  Used for contest leaderboard fetching
  """
  def fetch_top_popular_score_answers(question_id, number_of_answers) do
    Logger.info("Fetching top popular score answers for question #{question_id}")

    subquery =
      Answer
      |> where(question_id: ^question_id)
      |> where(
        [a],
        fragment(
          "?->>'code' like ?",
          a.answer,
          "%return%"
        )
      )
      |> order_by(desc: :popular_score)
      |> join(:left, [a], s in assoc(a, :submission))
      |> join(:left, [a, s], student in assoc(s, :student))
      |> join(:inner, [a, s, student], student_user in assoc(student, :user))
      |> where([a, s, student], student.role == "student")
      |> select([a, s, student, student_user], %{
        submission_id: a.submission_id,
        answer: a.answer,
        popular_score: a.popular_score,
        student_name: student_user.name,
        student_username: student_user.username,
        rank: fragment("RANK() OVER (ORDER BY ? DESC)", a.popular_score)
      })

    final_query =
      from(r in subquery(subquery),
        where: r.rank <= ^number_of_answers
      )

    Repo.all(final_query)
  end

  @doc """
  Computes rolling leaderboard for contest votes that are still open.
  """
  def update_rolling_contest_leaderboards do
    Logger.info("Updating rolling contest leaderboards")
    # 115 = 2 hours - 5 minutes is default.
    if Log.log_execution("update_rolling_contest_leaderboards", Duration.from_minutes(115)) do
      Logger.info("Started update_rolling_contest_leaderboards")

      voting_questions_to_update = fetch_active_voting_questions()

      _ =
        voting_questions_to_update
        |> Enum.map(fn qn -> compute_relative_score(qn.id) end)

      Logger.info("Successfully update_rolling_contest_leaderboards")
    end
  end

  def fetch_active_voting_questions do
    Question
    |> join(:left, [q], a in assoc(q, :assessment))
    |> where([q, a], q.type == "voting")
    |> where([q, a], a.is_published)
    |> where([q, a], a.open_at <= ^Timex.now() and a.close_at >= ^Timex.now())
    |> Repo.all()
  end

  @doc """
  Computes final leaderboard for contest votes that have closed.
  """
  def update_final_contest_leaderboards do
    Logger.info("Updating final contest leaderboards")
    # 1435 = 24 hours - 5 minutes
    if Log.log_execution("update_final_contest_leaderboards", Duration.from_minutes(1435)) do
      Logger.info("Started update_final_contest_leaderboards")

      voting_questions_to_update = fetch_voting_questions_due_yesterday() || []

      voting_questions_to_update =
        if is_nil(voting_questions_to_update), do: [], else: voting_questions_to_update

      scores =
        Enum.map(voting_questions_to_update, fn qn ->
          compute_relative_score(qn.id)
        end)

      if Enum.empty?(voting_questions_to_update) do
        Logger.warn("No voting questions to update.")
      else
        # Process each voting question
        Enum.each(voting_questions_to_update, fn qn ->
          assign_winning_contest_entries_xp(qn.id)
        end)

        Logger.info("Successfully update_final_contest_leaderboards")
      end

      scores
    end
  end

  def fetch_voting_questions_due_yesterday do
    Question
    |> join(:left, [q], a in assoc(q, :assessment))
    |> where([q, a], q.type == "voting")
    |> where([q, a], a.is_published)
    |> where([q, a], a.open_at <= ^Timex.now())
    |> where(
      [q, a],
      a.close_at < ^Timex.now() and a.close_at >= ^Timex.shift(Timex.now(), days: -1)
    )
    |> Repo.all()
  end

  @doc """
  Automatically assigns XP to the winning contest entries
  """
  def assign_winning_contest_entries_xp(contest_voting_question_id) do
    Logger.info(
      "Assigning XP to winning contest entries for question #{contest_voting_question_id}"
    )

    voting_questions =
      Question
      |> where(type: :voting)
      |> where(id: ^contest_voting_question_id)
      |> Repo.one()

    contest_question_id =
      SubmissionVotes
      |> where(question_id: ^contest_voting_question_id)
      |> join(:inner, [sv], ans in Answer, on: sv.submission_id == ans.submission_id)
      |> select([sv, ans], ans.question_id)
      |> limit(1)
      |> Repo.one()

    if is_nil(contest_question_id) do
      Logger.warn("Contest question ID is missing. Terminating.")
      :ok
    else
      default_xp_values = %Cadet.Assessments.QuestionTypes.VotingQuestion{} |> Map.get(:xp_values)
      scores = voting_questions.question["xp_values"] || default_xp_values

      if scores == [] do
        Logger.warn("No XP values provided. Terminating.")
        :ok
      else
        Repo.transaction(fn ->
          submission_ids =
            Answer
            |> where(question_id: ^contest_question_id)
            |> select([a], a.submission_id)
            |> Repo.all()

          Submission
          |> where([s], s.id in ^submission_ids)
          |> Repo.update_all(set: [is_grading_published: true])

          winning_popular_entries =
            Answer
            |> where(question_id: ^contest_question_id)
            |> select([a], %{
              id: a.id,
              rank: fragment("rank() OVER (ORDER BY ? DESC)", a.popular_score)
            })
            |> Repo.all()

          winning_popular_entries
          |> Enum.each(fn %{id: answer_id, rank: rank} ->
            increment = Enum.at(scores, rank - 1, 0)
            answer = Repo.get!(Answer, answer_id)
            Repo.update!(Changeset.change(answer, %{xp_adjustment: increment}))
          end)

          winning_score_entries =
            Answer
            |> where(question_id: ^contest_question_id)
            |> select([a], %{
              id: a.id,
              rank: fragment("rank() OVER (ORDER BY ? DESC)", a.relative_score)
            })
            |> Repo.all()

          winning_score_entries
          |> Enum.each(fn %{id: answer_id, rank: rank} ->
            increment = Enum.at(scores, rank - 1, 0)
            answer = Repo.get!(Answer, answer_id)
            new_value = answer.xp_adjustment + increment
            Repo.update!(Changeset.change(answer, %{xp_adjustment: new_value}))
          end)
        end)

        Logger.info("XP assigned to winning contest entries")
      end
    end
  end

  @doc """
  Computes the current relative_score of each voting submission answer
  based on current submitted votes.
  """
  def compute_relative_score(contest_voting_question_id) do
    Logger.info(
      "Computing relative score for contest voting question #{contest_voting_question_id}"
    )

    # reset all scores to 0 first
    voting_questions =
      Question
      |> where(type: :voting)
      |> where(id: ^contest_voting_question_id)
      |> Repo.one()

    if is_nil(voting_questions) do
      IO.puts("Voting question not found, skipping score computation.")
      :ok
    else
      course_id =
        Assessment
        |> where(id: ^voting_questions.assessment_id)
        |> select([a], a.course_id)
        |> Repo.one()

      if is_nil(course_id) do
        IO.puts("Course ID not found, skipping score computation.")
        :ok
      else
        contest_question_id = fetch_associated_contest_question_id(course_id, voting_questions)

        if !is_nil(contest_question_id) do
          # reset all scores to 0 first
          Answer
          |> where([ans], ans.question_id == ^contest_question_id)
          |> update([ans], set: [popular_score: 0.0, relative_score: 0.0])
          |> Repo.update_all([])
        end
      end
    end

    # query all records from submission votes tied to the question id ->
    # map score to user id ->
    # store as grade ->
    # query grade for contest question id.
    eligible_votes =
      SubmissionVotes
      |> where(question_id: ^contest_voting_question_id)
      |> where([sv], not is_nil(sv.score))
      |> join(:inner, [sv], ans in Answer, on: sv.submission_id == ans.submission_id)
      |> select(
        [sv, ans],
        %{ans_id: ans.id, score: sv.score, ans: ans.answer["code"]}
      )
      |> Repo.all()

    token_divider =
      Question
      |> select([q], q.question["token_divider"])
      |> Repo.get_by(id: contest_voting_question_id)

    entry_scores = map_eligible_votes_to_entry_score(eligible_votes, token_divider)
    normalized_scores = map_eligible_votes_to_popular_score(eligible_votes, token_divider)

    entry_scores
    |> Enum.map(fn {ans_id, relative_score} ->
      %Answer{id: ans_id}
      |> Answer.contest_score_update_changeset(%{
        relative_score: relative_score
      })
    end)
    |> Enum.map(fn changeset ->
      op_key = "answer_#{changeset.data.id}"
      Multi.update(Multi.new(), op_key, changeset)
    end)
    |> Enum.reduce(Multi.new(), &Multi.append/2)
    |> Repo.transaction()

    normalized_scores
    |> Enum.map(fn {ans_id, popular_score} ->
      %Answer{id: ans_id}
      |> Answer.popular_score_update_changeset(%{
        popular_score: popular_score
      })
    end)
    |> Enum.map(fn changeset ->
      op_key = "answer_#{changeset.data.id}"
      Multi.update(Multi.new(), op_key, changeset)
    end)
    |> Enum.reduce(Multi.new(), &Multi.append/2)
    |> Repo.transaction()
  end

  defp map_eligible_votes_to_entry_score(eligible_votes, token_divider) do
    Logger.info("Mapping eligible votes to entry scores")
    # converts eligible votes to the {total cumulative score, number of votes, tokens}
    entry_vote_data =
      Enum.reduce(eligible_votes, %{}, fn %{ans_id: ans_id, score: score, ans: ans}, tracker ->
        {prev_score, prev_count, _ans_tokens} = Map.get(tracker, ans_id, {0, 0, 0})

        Map.put(
          tracker,
          ans_id,
          # assume each voter is assigned 10 entries which will make it fair.
          {prev_score + score, prev_count + 1, Lexer.count_tokens(ans)}
        )
      end)

    # calculate the score based on formula {ans_id, score}
    Enum.map(
      entry_vote_data,
      fn {ans_id, {sum_of_scores, number_of_voters, tokens}} ->
        {ans_id, calculate_formula_score(sum_of_scores, number_of_voters, tokens, token_divider)}
      end
    )
  end

  defp map_eligible_votes_to_popular_score(eligible_votes, token_divider) do
    Logger.info("Mapping eligible votes to popular scores")
    # converts eligible votes to the {total cumulative score, number of votes, tokens}
    entry_vote_data =
      Enum.reduce(eligible_votes, %{}, fn %{ans_id: ans_id, score: score, ans: ans}, tracker ->
        {prev_score, prev_count, _ans_tokens} = Map.get(tracker, ans_id, {0, 0, 0})

        Map.put(
          tracker,
          ans_id,
          # assume each voter is assigned 10 entries which will make it fair.
          {prev_score + score, prev_count + 1, Lexer.count_tokens(ans)}
        )
      end)

    # calculate the score based on formula {ans_id, score}
    Enum.map(
      entry_vote_data,
      fn {ans_id, {sum_of_scores, number_of_voters, tokens}} ->
        {ans_id,
         calculate_normalized_score(sum_of_scores, number_of_voters, tokens, token_divider)}
      end
    )
  end

  # Calculate the score based on formula
  # score(v,t) = v - 2^(t/token_divider) where v is the normalized_voting_score
  # normalized_voting_score = sum_of_scores / number_of_voters / 10 * 100
  defp calculate_formula_score(sum_of_scores, number_of_voters, tokens, token_divider) do
    Logger.info("Calculating formula score")

    normalized_voting_score =
      calculate_normalized_score(sum_of_scores, number_of_voters, tokens, token_divider)

    normalized_voting_score - :math.pow(2, min(1023.5, tokens / token_divider))
  end

  # Calculate the normalized score based on formula
  # normalized_voting_score = sum_of_scores / number_of_voters / 10 * 100
  defp calculate_normalized_score(sum_of_scores, number_of_voters, _tokens, _token_divider) do
    Logger.info("Calculating normalized score")
    sum_of_scores / number_of_voters / 10 * 100
  end

  @doc """
  Function returning submissions under a grader. This function returns only the
  fields that are exposed in the /grading endpoint.

  The input parameters are the user and query parameters. Query parameters are
  used to filter the submissions.

  The return value is `{:ok, %{"count": count, "data": submissions}}`

  # Params
  Refer to admin_grading_controller.ex/index for the list of query parameters.

  # Implementation
  Uses helper functions to build the filter query. Helper functions are separated by tables in the database.
  """

  @spec submissions_by_grader_for_index(CourseRegistration.t(), map()) ::
          {:ok,
           %{
             :count => integer,
             :data => %{
               :assessments => [any()],
               :submissions => [any()],
               :users => [any()],
               :teams => [any()],
               :team_members => [any()]
             }
           }}
  def submissions_by_grader_for_index(
        grader = %CourseRegistration{course_id: course_id},
        params
      ) do
    submission_answers_query =
      from(ans in Answer,
        group_by: ans.submission_id,
        select: %{
          submission_id: ans.submission_id,
          xp: sum(ans.xp),
          xp_adjustment: sum(ans.xp_adjustment),
          graded_count: filter(count(ans.id), not is_nil(ans.grader_id))
        }
      )

    question_answers_query =
      from(q in Question,
        group_by: q.assessment_id,
        join: a in Assessment,
        on: q.assessment_id == a.id,
        select: %{
          assessment_id: q.assessment_id,
          question_count: count(q.id),
          title: max(a.title),
          config_id: max(a.config_id)
        }
      )

    query =
      from(s in Submission,
        left_join: ans in subquery(submission_answers_query),
        on: ans.submission_id == s.id,
        as: :ans,
        left_join: asst in subquery(question_answers_query),
        on: asst.assessment_id == s.assessment_id,
        as: :asst,
        left_join: cr in CourseRegistration,
        on: s.student_id == cr.id,
        as: :cr,
        left_join: user in User,
        on: user.id == cr.user_id,
        as: :user,
        left_join: group in Group,
        on: cr.group_id == group.id,
        as: :group,
        inner_join: config in AssessmentConfig,
        on: asst.config_id == config.id,
        as: :config,
        where: ^build_user_filter(params),
        where: s.assessment_id in subquery(build_assessment_filter(params, course_id)),
        where: s.assessment_id in subquery(build_assessment_config_filter(params)),
        where: ^build_submission_filter(params),
        where: ^build_course_registration_filter(params, grader),
        limit: ^params[:page_size],
        offset: ^params[:offset],
        select: %{
          id: s.id,
          status: s.status,
          xp_bonus: s.xp_bonus,
          unsubmitted_at: s.unsubmitted_at,
          unsubmitted_by_id: s.unsubmitted_by_id,
          student_id: s.student_id,
          team_id: s.team_id,
          assessment_id: s.assessment_id,
          is_grading_published: s.is_grading_published,
          xp: ans.xp,
          xp_adjustment: ans.xp_adjustment,
          graded_count: ans.graded_count,
          question_count: asst.question_count
        }
      )

    query = sort_submission(query, params[:sort_by], params[:sort_direction])

    query =
      from([s, ans, asst, cr, user, group] in query, order_by: [desc: s.inserted_at, asc: s.id])

    submissions = Repo.all(query)

    count_query =
      from(s in Submission,
        left_join: ans in subquery(submission_answers_query),
        on: ans.submission_id == s.id,
        as: :ans,
        left_join: asst in subquery(question_answers_query),
        on: asst.assessment_id == s.assessment_id,
        as: :asst,
        where: s.assessment_id in subquery(build_assessment_filter(params, course_id)),
        where: s.assessment_id in subquery(build_assessment_config_filter(params)),
        where: ^build_user_filter(params),
        where: ^build_submission_filter(params),
        where: ^build_course_registration_filter(params, grader),
        select: count(s.id)
      )

    count = Repo.one(count_query)

    {:ok, %{count: count, data: generate_grading_summary_view_model(submissions, course_id)}}
  end

  # Given a query from submissions_by_grader_for_index,
  # sorts it by the relevant field and direction.
  defp sort_submission(query, sort_by, sort_direction)
       when sort_direction in [:asc, :desc] do
    case sort_by do
      :assessment_name ->
        from([s, ans, asst, cr, user, group, config] in query,
          order_by: [{^sort_direction, fragment("upper(?)", asst.title)}]
        )

      :assessment_type ->
        from([s, ans, asst, cr, user, group, config] in query,
          order_by: [{^sort_direction, asst.config_id}]
        )

      :student_name ->
        from([s, ans, asst, cr, user, group, config] in query,
          order_by: [{^sort_direction, fragment("upper(?)", user.name)}]
        )

      :student_username ->
        from([s, ans, asst, cr, user, group, config] in query,
          order_by: [{^sort_direction, fragment("upper(?)", user.username)}]
        )

      :group_name ->
        from([s, ans, asst, cr, user, group, config] in query,
          order_by: [{^sort_direction, fragment("upper(?)", group.name)}]
        )

      :progress_status ->
        from([s, ans, asst, cr, user, group, config] in query,
          order_by: [
            {^sort_direction, config.is_manually_graded},
            {^sort_direction, s.status},
            {^sort_direction, ans.graded_count - asst.question_count},
            {^sort_direction, s.is_grading_published}
          ]
        )

      :xp ->
        from([s, ans, asst, cr, user, group, config] in query,
          order_by: [{^sort_direction, ans.xp + ans.xp_adjustment}]
        )

      _ ->
        query
    end
  end

  defp sort_submission(query, _sort_by, _sort_direction), do: query

  def parse_sort_direction(params) do
    case params[:sort_direction] do
      "sort-asc" -> Map.put(params, :sort_direction, :asc)
      "sort-desc" -> Map.put(params, :sort_direction, :desc)
      _ -> Map.put(params, :sort_direction, nil)
    end
  end

  def parse_sort_by(params) do
    case params[:sort_by] do
      "assessmentName" -> Map.put(params, :sort_by, :assessment_name)
      "assessmentType" -> Map.put(params, :sort_by, :assessment_type)
      "studentName" -> Map.put(params, :sort_by, :student_name)
      "studentUsername" -> Map.put(params, :sort_by, :student_username)
      "groupName" -> Map.put(params, :sort_by, :group_name)
      "progressStatus" -> Map.put(params, :sort_by, :progress_status)
      "xp" -> Map.put(params, :sort_by, :xp)
      _ -> Map.put(params, :sort_by, nil)
    end
  end

  defp build_assessment_filter(params, course_id) do
    assessments_filters =
      Enum.reduce(params, dynamic(true), fn
        {:title, value}, dynamic ->
          dynamic([assessment], ^dynamic and ilike(assessment.title, ^"%#{value}%"))

        {_, _}, dynamic ->
          dynamic
      end)

    from(a in Assessment,
      where: a.course_id == ^course_id,
      where: ^assessments_filters,
      select: a.id
    )
  end

  defp build_submission_filter(params) do
    Enum.reduce(params, dynamic(true), fn
      {:status, value}, dynamic ->
        dynamic([submission], ^dynamic and submission.status == ^value)

      {:is_fully_graded, value}, dynamic ->
        dynamic(
          [ans: ans, asst: asst],
          ^dynamic and asst.question_count == ans.graded_count == ^value
        )

      {:is_grading_published, value}, dynamic ->
        dynamic([submission], ^dynamic and submission.is_grading_published == ^value)

      {_, _}, dynamic ->
        dynamic
    end)
  end

  defp build_course_registration_filter(params, grader) do
    Enum.reduce(params, dynamic(true), fn
      {:group, true}, dynamic ->
        dynamic(
          [submission],
          (^dynamic and
             submission.student_id in subquery(
               from(cr in CourseRegistration,
                 join: g in Group,
                 on: cr.group_id == g.id,
                 where: g.leader_id == ^grader.id,
                 select: cr.id
               )
             )) or submission.student_id == ^grader.id
        )

      {:group_name, value}, dynamic ->
        dynamic(
          [submission],
          ^dynamic and
            submission.student_id in subquery(
              from(cr in CourseRegistration,
                join: g in Group,
                on: cr.group_id == g.id,
                where: g.name == ^value,
                select: cr.id
              )
            )
        )

      {_, _}, dynamic ->
        dynamic
    end)
  end

  defp build_user_filter(params) do
    Enum.reduce(params, dynamic(true), fn
      {:name, value}, dynamic ->
        dynamic(
          [submission],
          ^dynamic and
            submission.student_id in subquery(
              from(user in User,
                where: ilike(user.name, ^"%#{value}%"),
                inner_join: cr in CourseRegistration,
                on: user.id == cr.user_id,
                select: cr.id
              )
            )
        )

      {:username, value}, dynamic ->
        dynamic(
          [submission],
          ^dynamic and
            submission.student_id in subquery(
              from(user in User,
                where: ilike(user.username, ^"%#{value}%"),
                inner_join: cr in CourseRegistration,
                on: user.id == cr.user_id,
                select: cr.id
              )
            )
        )

      {_, _}, dynamic ->
        dynamic
    end)
  end

  defp build_assessment_config_filter(params) do
    assessment_config_filters =
      Enum.reduce(params, dynamic(true), fn
        {:type, value}, dynamic ->
          dynamic([assessment_config: config], ^dynamic and config.type == ^value)

        {:is_manually_graded, value}, dynamic ->
          dynamic([assessment_config: config], ^dynamic and config.is_manually_graded == ^value)

        {_, _}, dynamic ->
          dynamic
      end)

    from(a in Assessment,
      inner_join: config in AssessmentConfig,
      on: a.config_id == config.id,
      as: :assessment_config,
      where: ^assessment_config_filters,
      select: a.id
    )
  end

  defp generate_grading_summary_view_model(submissions, course_id) do
    users =
      CourseRegistration
      |> where([cr], cr.course_id == ^course_id)
      |> join(:inner, [cr], u in assoc(cr, :user))
      |> join(:left, [cr, u], g in assoc(cr, :group))
      |> preload([cr, u, g], user: u, group: g)
      |> Repo.all()

    assessment_ids = submissions |> Enum.map(& &1.assessment_id) |> Enum.uniq()

    assessments =
      Assessment
      |> where([a], a.id in ^assessment_ids)
      |> join(:left, [a], q in assoc(a, :questions))
      |> join(:inner, [a], ac in assoc(a, :config))
      |> preload([a, q, ac], questions: q, config: ac)
      |> Repo.all()

    team_ids = submissions |> Enum.map(& &1.team_id) |> Enum.uniq()

    teams =
      Team
      |> where([t], t.id in ^team_ids)
      |> Repo.all()

    team_members =
      TeamMember
      |> where([tm], tm.team_id in ^team_ids)
      |> Repo.all()

    %{
      users: users,
      assessments: assessments,
      submissions: submissions,
      teams: teams,
      team_members: team_members
    }
  end

  @spec get_answer(integer() | String.t()) ::
          {:ok, Answer.t()} | {:error, {:bad_request, String.t()}}
  def get_answer(id) when is_ecto_id(id) do
    answer =
      Answer
      |> where(id: ^id)
      # [a] are bindings (in SQL it is similar to FROM answers "AS a"),
      # this line's alias is INNER JOIN ... "AS q"
      |> join(:inner, [a], q in assoc(a, :question))
      |> join(:inner, [_, q], ast in assoc(q, :assessment))
      |> join(:inner, [..., ast], ac in assoc(ast, :config))
      |> join(:left, [a, ...], g in assoc(a, :grader))
      |> join(:left, [_, ..., g], gu in assoc(g, :user))
      |> join(:inner, [a, ...], s in assoc(a, :submission))
      |> join(:left, [_, ..., s], st in assoc(s, :student))
      |> join(:left, [..., st], u in assoc(st, :user))
      |> join(:left, [..., s, _, _], t in assoc(s, :team))
      |> join(:left, [..., t], tm in assoc(t, :team_members))
      |> join(:left, [..., tm], tms in assoc(tm, :student))
      |> join(:left, [..., tms], tmu in assoc(tms, :user))
      |> join(:left, [a, ...], ai in assoc(a, :ai_comments))
      |> preload([_, q, ast, ac, g, gu, s, st, u, t, tm, tms, tmu, ai],
        ai_comments: ai,
        question: {q, assessment: {ast, config: ac}},
        grader: {g, user: gu},
        submission:
          {s, student: {st, user: u}, team: {t, team_members: {tm, student: {tms, user: tmu}}}}
      )
      |> Repo.one()

    if is_nil(answer) do
      {:error, {:bad_request, "Answer not found."}}
    else
      if answer.question.type == :voting do
        empty_contest_entries = Map.put(answer.question.question, :contest_entries, [])
        empty_popular_leaderboard = Map.put(empty_contest_entries, :popular_leaderboard, [])
        empty_contest_leaderboard = Map.put(empty_popular_leaderboard, :contest_leaderboard, [])
        question = Map.put(answer.question, :question, empty_contest_leaderboard)
        Map.put(answer, :question, question)
      end

      {:ok, answer}
    end
  end

  @spec get_answers_in_submission(integer() | String.t()) ::
          {:ok, {[Answer.t()], Assessment.t()}}
          | {:error, {:bad_request, String.t()}}
  def get_answers_in_submission(id) when is_ecto_id(id) do
    base_query =
      Answer
      |> where(submission_id: ^id)
      # [a] are bindings (in SQL it is similar to FROM answers "AS a"),
      # this line's alias is INNER JOIN ... "AS q"
      |> join(:inner, [a], q in assoc(a, :question))
      |> join(:inner, [_, q], ast in assoc(q, :assessment))
      |> join(:inner, [..., ast], ac in assoc(ast, :config))
      |> join(:left, [a, ...], g in assoc(a, :grader))
      |> join(:left, [_, ..., g], gu in assoc(g, :user))
      |> join(:inner, [a, ...], s in assoc(a, :submission))
      |> join(:left, [_, ..., s], st in assoc(s, :student))
      |> join(:left, [..., st], u in assoc(st, :user))
      |> join(:left, [..., s, _, _], t in assoc(s, :team))
      |> join(:left, [..., t], tm in assoc(t, :team_members))
      |> join(:left, [..., tm], tms in assoc(tm, :student))
      |> join(:left, [..., tms], tmu in assoc(tms, :user))
      |> join(:left, [a, ...], ai in assoc(a, :ai_comments))
      |> preload([_, q, ast, ac, g, gu, s, st, u, t, tm, tms, tmu, ai],
        question: {q, assessment: {ast, config: ac}},
        grader: {g, user: gu},
        submission:
          {s, student: {st, user: u}, team: {t, team_members: {tm, student: {tms, user: tmu}}}},
        ai_comments: ai
      )

    answers =
      base_query
      |> Repo.all()
      |> Enum.sort_by(& &1.question.display_order)
      |> Enum.map(fn ans ->
        if ans.question.type == :voting do
          empty_contest_entries = Map.put(ans.question.question, :contest_entries, [])
          empty_popular_leaderboard = Map.put(empty_contest_entries, :popular_leaderboard, [])
          empty_contest_leaderboard = Map.put(empty_popular_leaderboard, :contest_leaderboard, [])
          question = Map.put(ans.question, :question, empty_contest_leaderboard)
          Map.put(ans, :question, question)
        else
          ans
        end
      end)

    if answers == [] do
      {:error, {:bad_request, "Submission is not found."}}
    else
      assessment_id = Submission |> where(id: ^id) |> select([s], s.assessment_id) |> Repo.one()
      assessment = Assessment |> where(id: ^assessment_id) |> Repo.one()
      {:ok, {answers, assessment}}
    end
  end

  defp is_fully_graded?(submission_id) do
    submission =
      Submission
      |> Repo.get_by(id: submission_id)

    question_count =
      Question
      |> where(assessment_id: ^submission.assessment_id)
      |> select([q], count(q.id))
      |> Repo.one()

    graded_count =
      Answer
      |> where([a], submission_id: ^submission_id)
      |> where([a], not is_nil(a.grader_id))
      |> select([a], count(a.id))
      |> Repo.one()

    question_count == graded_count
  end

  def is_fully_autograded?(submission_id) do
    submission =
      Submission
      |> Repo.get_by(id: submission_id)

    question_count =
      Question
      |> where(assessment_id: ^submission.assessment_id)
      |> select([q], count(q.id))
      |> Repo.one()

    graded_count =
      Answer
      |> where([a], submission_id: ^submission_id)
      |> where([a], a.autograding_status == :success)
      |> select([a], count(a.id))
      |> Repo.one()

    question_count == graded_count
  end

  @spec update_grading_info(
          %{submission_id: integer() | String.t(), question_id: integer() | String.t()},
          %{},
          CourseRegistration.t()
        ) ::
          {:ok, nil}
          | {:error, {:forbidden | :bad_request | :internal_server_error, String.t()}}
  def update_grading_info(
        %{submission_id: submission_id, question_id: question_id},
        attrs,
        cr = %CourseRegistration{id: grader_id}
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) do
    attrs = Map.put(attrs, "grader_id", grader_id)

    answer_query =
      Answer
      |> where(submission_id: ^submission_id)
      |> where(question_id: ^question_id)

    answer_query =
      answer_query
      |> join(:inner, [a], s in assoc(a, :submission))
      |> preload([_, s], submission: s)

    answer = Repo.one(answer_query)

    is_own_submission = grader_id == answer.submission.student_id

    submission =
      Submission
      |> join(:inner, [s], a in assoc(s, :assessment))
      |> preload([_, a], assessment: {a, :config})
      |> Repo.get(submission_id)

    is_grading_auto_published = submission.assessment.config.is_grading_auto_published

    with {:answer_found?, true} <- {:answer_found?, is_map(answer)},
         {:status, true} <-
           {:status, answer.submission.status == :submitted or is_own_submission},
         {:valid, changeset = %Ecto.Changeset{valid?: true}} <-
           {:valid, Answer.grading_changeset(answer, attrs)},
         {:ok, _} <- Repo.update(changeset) do
      update_xp_bonus(submission)

      if is_grading_auto_published and is_fully_graded?(submission_id) do
        publish_grading(submission_id, cr)
      end

      {:ok, nil}
    else
      {:answer_found?, false} ->
        {:error, {:bad_request, "Answer not found or user not permitted to grade."}}

      {:valid, changeset} ->
        {:error, {:bad_request, full_error_messages(changeset)}}

      {:status, _} ->
        {:error, {:method_not_allowed, "Submission is not submitted yet."}}

      {:error, _} ->
        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  def update_grading_info(
        _,
        _,
        _
      ) do
    {:error, {:forbidden, "User is not permitted to grade."}}
  end

  @spec force_regrade_submission(integer() | String.t(), CourseRegistration.t()) ::
          {:ok, nil} | {:error, {:forbidden | :not_found, String.t()}}
  def force_regrade_submission(
        submission_id,
        _requesting_user = %CourseRegistration{id: grader_id}
      )
      when is_ecto_id(submission_id) do
    with {:get, sub} when not is_nil(sub) <- {:get, Repo.get(Submission, submission_id)},
         {:status, true} <- {:status, sub.student_id == grader_id or sub.status == :submitted} do
      GradingJob.force_grade_individual_submission(sub, true)
      {:ok, nil}
    else
      {:get, nil} ->
        {:error, {:not_found, "Submission not found"}}

      {:status, false} ->
        {:error, {:bad_request, "Submission not submitted yet"}}
    end
  end

  def force_regrade_submission(_, _) do
    {:error, {:forbidden, "User is not permitted to grade."}}
  end

  @spec force_regrade_answer(
          integer() | String.t(),
          integer() | String.t(),
          CourseRegistration.t()
        ) ::
          {:ok, nil} | {:error, {:forbidden | :not_found, String.t()}}
  def force_regrade_answer(
        submission_id,
        question_id,
        _requesting_user = %CourseRegistration{id: grader_id}
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) do
    answer =
      Answer
      |> where(submission_id: ^submission_id, question_id: ^question_id)
      |> preload([:question, :submission])
      |> Repo.one()

    with {:get, answer} when not is_nil(answer) <- {:get, answer},
         {:status, true} <-
           {:status,
            answer.submission.student_id == grader_id or answer.submission.status == :submitted} do
      GradingJob.grade_answer(answer, answer.question, true)
      {:ok, nil}
    else
      {:get, nil} ->
        {:error, {:not_found, "Answer not found"}}

      {:status, false} ->
        {:error, {:bad_request, "Submission not submitted yet"}}
    end
  end

  def force_regrade_answer(_, _, _) do
    {:error, {:forbidden, "User is not permitted to grade."}}
  end

  defp find_submission(cr = %CourseRegistration{}, assessment = %Assessment{}) do
    {:ok, team} = find_team(assessment.id, cr.id)

    submission =
      case team do
        %Team{} ->
          Submission
          |> where(team_id: ^team.id)
          |> where(assessment_id: ^assessment.id)
          |> Repo.one()

        nil ->
          Submission
          |> where(student_id: ^cr.id)
          |> where(assessment_id: ^assessment.id)
          |> Repo.one()
      end

    if submission do
      {:ok, submission}
    else
      {:error, nil}
    end
  end

  # Checks if an assessment is open and published.
  @spec is_open?(Assessment.t()) :: boolean()
  def is_open?(%Assessment{open_at: open_at, close_at: close_at, is_published: is_published}) do
    Timex.between?(Timex.now(), open_at, close_at, inclusive: :start) and is_published
  end

  @spec get_group_grading_summary(integer()) ::
          {:ok, [String.t(), ...], []}
  def get_group_grading_summary(course_id) do
    subs =
      Answer
      |> join(:left, [ans], s in Submission, on: s.id == ans.submission_id)
      |> join(:left, [ans, s], st in CourseRegistration, on: s.student_id == st.id)
      |> join(:left, [ans, s, st], a in Assessment, on: a.id == s.assessment_id)
      |> join(:inner, [ans, s, st, a], ac in AssessmentConfig, on: ac.id == a.config_id)
      |> where(
        [ans, s, st, a, ac],
        not is_nil(st.group_id) and s.status == ^:submitted and
          ac.show_grading_summary and a.course_id == ^course_id
      )
      |> group_by([ans, s, st, a, ac], s.id)
      |> select([ans, s, st, a, ac], %{
        group_id: max(st.group_id),
        config_id: max(ac.id),
        config_type: max(ac.type),
        num_submitted: count(),
        num_ungraded: filter(count(), is_nil(ans.grader_id))
      })

    raw_data =
      subs
      |> subquery()
      |> join(:left, [t], g in Group, on: t.group_id == g.id)
      |> join(:left, [t, g], l in CourseRegistration, on: l.id == g.leader_id)
      |> join(:left, [t, g, l], lu in User, on: lu.id == l.user_id)
      |> group_by([t, g, l, lu], [t.group_id, t.config_id, t.config_type, g.name, lu.name])
      |> select([t, g, l, lu], %{
        group_name: g.name,
        leader_name: lu.name,
        config_id: t.config_id,
        config_type: t.config_type,
        ungraded: filter(count(), t.num_ungraded > 0),
        submitted: count()
      })
      |> Repo.all()

    showing_configs =
      AssessmentConfig
      |> where([ac], ac.course_id == ^course_id and ac.show_grading_summary)
      |> order_by(:order)
      |> group_by([ac], ac.id)
      |> select([ac], %{
        id: ac.id,
        type: ac.type
      })
      |> Repo.all()

    data_by_groups =
      raw_data
      |> Enum.reduce(%{}, fn raw, acc ->
        if Map.has_key?(acc, raw.group_name) do
          acc
          |> put_in([raw.group_name, "ungraded" <> raw.config_type], raw.ungraded)
          |> put_in([raw.group_name, "submitted" <> raw.config_type], raw.submitted)
        else
          acc
          |> put_in([raw.group_name], %{})
          |> put_in([raw.group_name, "groupName"], raw.group_name)
          |> put_in([raw.group_name, "leaderName"], raw.leader_name)
          |> put_in([raw.group_name, "ungraded" <> raw.config_type], raw.ungraded)
          |> put_in([raw.group_name, "submitted" <> raw.config_type], raw.submitted)
        end
      end)

    headings =
      showing_configs
      |> Enum.reduce([], fn config, acc ->
        acc ++ ["submitted" <> config.type, "ungraded" <> config.type]
      end)

    default_row_data =
      headings
      |> Enum.reduce(%{}, fn heading, acc ->
        put_in(acc, [heading], 0)
      end)

    rows = data_by_groups |> Enum.map(fn {_k, row} -> Map.merge(default_row_data, row) end)
    cols = ["groupName", "leaderName"] ++ headings

    {:ok, cols, rows}
  end

  defp create_empty_submission(cr = %CourseRegistration{}, assessment = %Assessment{}) do
    {:ok, team} = find_team(assessment.id, cr.id)

    case team do
      %Team{} ->
        %Submission{}
        |> Submission.changeset(%{team: team, assessment: assessment})
        |> Repo.insert()
        |> case do
          {:ok, submission} -> {:ok, submission}
        end

      nil ->
        %Submission{}
        |> Submission.changeset(%{student: cr, assessment: assessment})
        |> Repo.insert()
        |> case do
          {:ok, submission} -> {:ok, submission}
        end
    end
  end

  defp find_or_create_submission(cr = %CourseRegistration{}, assessment = %Assessment{}) do
    case find_submission(cr, assessment) do
      {:ok, submission} -> {:ok, submission}
      {:error, _} -> create_empty_submission(cr, assessment)
    end
  end

  defp insert_or_update_answer(
         submission = %Submission{},
         question = %Question{},
         raw_answer,
         course_reg_id
       ) do
    answer_content = build_answer_content(raw_answer, question.type)

    if question.type == :voting do
      insert_or_update_voting_answer(submission.id, course_reg_id, question.id, answer_content)
    else
      answer_changeset =
        %Answer{}
        |> Answer.changeset(%{
          answer: answer_content,
          question_id: question.id,
          submission_id: submission.id,
          type: question.type,
          last_modified_at: Timex.now()
        })

      Repo.insert(
        answer_changeset,
        on_conflict: [
          set: [answer: get_change(answer_changeset, :answer), last_modified_at: Timex.now()]
        ],
        conflict_target: [:submission_id, :question_id]
      )
    end
  end

  def has_last_modified_answer?(
        question = %Question{},
        cr = %CourseRegistration{id: _cr_id},
        last_modified_at,
        force_submit
      ) do
    with {:ok, submission} <- find_or_create_submission(cr, question.assessment),
         {:status, true} <- {:status, force_submit or submission.status != :submitted},
         {:ok, is_modified} <- answer_last_modified?(submission, question, last_modified_at) do
      {:ok, is_modified}
    else
      {:status, _} ->
        {:error, {:forbidden, "Assessment submission already finalised"}}
    end
  end

  defp answer_last_modified?(
         submission = %Submission{},
         question = %Question{},
         last_modified_at
       ) do
    case Repo.get_by(Answer, submission_id: submission.id, question_id: question.id) do
      %Answer{last_modified_at: existing_last_modified_at} ->
        existing_iso8601 = DateTime.to_iso8601(existing_last_modified_at)

        if existing_iso8601 == last_modified_at do
          {:ok, false}
        else
          {:ok, true}
        end

      nil ->
        {:ok, false}
    end
  end

  def insert_or_update_voting_answer(submission_id, course_reg_id, question_id, answer_content) do
    set_score_to_nil =
      SubmissionVotes
      |> where(voter_id: ^course_reg_id, question_id: ^question_id)

    voting_multi =
      Multi.new()
      |> Multi.update_all(:set_score_to_nil, set_score_to_nil, set: [score: nil])

    answer_content
    |> Enum.with_index(1)
    |> Enum.reduce(voting_multi, fn {entry, index}, multi ->
      multi
      |> Multi.run("update#{index}", fn _repo, _ ->
        SubmissionVotes
        |> Repo.get_by(
          voter_id: course_reg_id,
          submission_id: entry.submission_id
        )
        |> SubmissionVotes.changeset(%{score: entry.score})
        |> Repo.insert_or_update()
      end)
    end)
    |> Multi.run("insert into answer table", fn _repo, _ ->
      Answer
      |> Repo.get_by(submission_id: submission_id, question_id: question_id)
      |> case do
        nil ->
          Repo.insert(%Answer{
            answer: %{completed: true},
            submission_id: submission_id,
            question_id: question_id,
            type: :voting
          })

        _ ->
          {:ok, nil}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _result} -> {:ok, nil}
      {:error, _name, _changeset, _error} -> {:error, :invalid_vote}
    end
  end

  defp build_answer_content(raw_answer, question_type) do
    case question_type do
      :mcq ->
        %{choice_id: raw_answer}

      :programming ->
        %{code: raw_answer}

      :voting ->
        raw_answer
        |> Enum.map(fn ans ->
          for {key, value} <- ans, into: %{}, do: {String.to_existing_atom(key), value}
        end)
    end
  end

  def get_llm_assessment_prompt(question_id) do
    query =
      from(q in Question,
        where: q.id == ^question_id,
        join: a in assoc(q, :assessment),
        select: a.llm_assessment_prompt
      )

    Repo.one(query)
  end
end
