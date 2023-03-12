defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]
  import Ecto.Query

  require Logger

  alias Cadet.Accounts.{
    Notification,
    Notifications,
    User,
    CourseRegistration,
    CourseRegistrations
  }

  alias Cadet.Assessments.{Answer, Assessment, Query, Question, Submission, SubmissionVotes}
  alias Cadet.Autograder.GradingJob
  alias Cadet.Courses.{Group, AssessmentConfig}
  alias Cadet.Jobs.Log
  alias Cadet.ProgramAnalysis.Lexer
  alias Ecto.Multi
  alias Cadet.Incentives.Achievements

  require Decimal

  @open_all_assessment_roles ~w(staff admin)a

  # These roles can save and finalise answers for closed assessments and
  # submitted answers
  @bypass_closed_roles ~w(staff admin)a

  def delete_assessment(id) do
    assessment = Repo.get(Assessment, id)

    Submission
    |> where(assessment_id: ^id)
    |> delete_submission_assocation(id)

    Question
    |> where(assessment_id: ^id)
    |> Repo.all()
    |> Enum.each(fn q ->
      delete_submission_votes_association(q)
    end)

    Repo.delete(assessment)
  end

  defp delete_submission_votes_association(question) do
    SubmissionVotes
    |> where(question_id: ^question.id)
    |> Repo.delete_all()
  end

  defp delete_submission_assocation(submissions, assessment_id) do
    submissions
    |> Repo.all()
    |> Enum.each(fn submission ->
      Answer
      |> where(submission_id: ^submission.id)
      |> Repo.delete_all()
    end)

    Notification
    |> where(assessment_id: ^assessment_id)
    |> Repo.delete_all()

    Repo.delete_all(submissions)
  end

  @spec user_max_xp(CourseRegistration.t()) :: integer()
  def user_max_xp(%CourseRegistration{id: cr_id}) do
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
  end

  def assessments_total_xp(%CourseRegistration{id: cr_id}) do
    submission_xp =
      Submission
      |> where(student_id: ^cr_id)
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

    # for {key, val} <- total, into: %{}, do: {key, decimal_to_integer(val)}
    decimal_to_integer(total.total_xp)
  end

  def user_total_xp(course_id, user_id, course_reg_id) do
    user_course = CourseRegistrations.get_user_course(user_id, course_id)

    total_achievement_xp = Achievements.achievements_total_xp(course_id, course_reg_id)
    total_assessment_xp = assessments_total_xp(user_course)

    total_achievement_xp + total_assessment_xp
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
      assessment_with_questions_and_answers(assessment, cr, password)
    else
      {:error, {:bad_request, "Assessment not found"}}
    end
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{id: id},
        course_reg = %CourseRegistration{role: role}
      ) do
    if Timex.compare(Timex.now(), assessment.open_at) >= 0 or role in @open_all_assessment_roles do
      answer_query =
        Answer
        |> join(:inner, [a], s in assoc(a, :submission))
        |> where([_, s], s.student_id == ^course_reg.id)

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
        |> load_contest_voting_entries(course_reg, assessment)

      assessment = assessment |> Map.put(:questions, questions)
      {:ok, assessment}
    else
      {:error, {:unauthorized, "Assessment not open"}}
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
    submission_aggregates =
      Submission
      |> join(:left, [s], ans in Answer, on: ans.submission_id == s.id)
      |> where([s], s.student_id == ^cr.id)
      |> group_by([s], s.assessment_id)
      |> select([s, ans], %{
        assessment_id: s.assessment_id,
        # s.xp_bonus should be the same across the group, but we need an aggregate function here
        xp: fragment("? + ? + ?", sum(ans.xp), sum(ans.xp_adjustment), max(s.xp_bonus)),
        graded_count: ans.id |> count() |> filter(not is_nil(ans.grader_id))
      })

    submission_status =
      Submission
      |> where([s], s.student_id == ^cr.id)
      |> select([s], [:assessment_id, :status])

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
          user_status: s.status
      })
      |> filter_published_assessments(cr)
      |> order_by(:open_at)
      |> preload(:config)
      |> Repo.all()

    {:ok, assessments}
  end

  def filter_published_assessments(assessments, cr) do
    role = cr.role

    case role do
      :student -> where(assessments, is_published: true)
      _ -> assessments
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
    assessment_multi =
      Multi.insert_or_update(
        Multi.new(),
        :assessment,
        insert_or_update_assessment_changeset(assessment_params, force_update)
      )

    if force_update and invalid_force_update(assessment_multi, questions_params) do
      {:error, "Question count is different"}
    else
      questions_params
      |> Enum.with_index(1)
      |> Enum.reduce(assessment_multi, fn {question_params, index}, multi ->
        Multi.run(multi, "question#{index}", fn _repo, %{assessment: %Assessment{id: id}} ->
          question =
            Question
            |> where([q], q.display_order == ^index and q.assessment_id == ^id)
            |> Repo.one()

          # the is_nil(question) check allows for force updating of brand new assessments
          if !force_update or is_nil(question) do
            {status, new_question} =
              question_params
              |> Map.put(:display_order, index)
              |> build_question_changeset_for_assessment_id(id)
              |> Repo.insert()

            if status == :ok and new_question.type == :voting do
              insert_voting(
                assessment_params.course_id,
                question_params.question.contest_number,
                new_question.id
              )
            else
              {status, new_question}
            end
          else
            params =
              question_params
              |> Map.put_new(:max_xp, 0)
              |> Map.put(:display_order, index)

            if question_params.type != Atom.to_string(question.type) do
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
    assessment_id =
      (assessment_multi.operations
       |> List.first()
       |> elem(1)
       |> elem(1)).data.id

    if assessment_id do
      open_date = Repo.get(Assessment, assessment_id).open_at
      # check if assessment is already opened
      if Timex.compare(open_date, Timex.now()) >= 0 do
        false
      else
        existing_questions_count =
          Question
          |> where([q], q.assessment_id == ^assessment_id)
          |> Repo.all()
          |> Enum.count()

        new_questions_count = Enum.count(questions_params)
        existing_questions_count != new_questions_count
      end
    else
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
        Assessment.changeset(%Assessment{}, params)

      %{id: assessment_id} = assessment ->
        answers_exist =
          Answer
          |> join(:inner, [a], q in assoc(a, :question))
          |> join(:inner, [a, q], asst in assoc(q, :assessment))
          |> where([a, q, asst], asst.id == ^assessment_id)
          |> Repo.exists?()

        # Maintain the same open/close date when updating an assessment
        params =
          params
          |> Map.delete(:open_at)
          |> Map.delete(:close_at)
          |> Map.delete(:is_published)

        cond do
          not answers_exist ->
            # Delete all realted submission_votes
            SubmissionVotes
            |> join(:inner, [sv, q], q in assoc(sv, :question))
            |> where([sv, q], q.assessment_id == ^assessment_id)
            |> Repo.delete_all()

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

  @doc """
  Generates and assigns contest entries for users with given usernames.
  """
  def insert_voting(
        course_id,
        contest_number,
        question_id
      ) do
    contest_assessment = Repo.get_by(Assessment, number: contest_number, course_id: course_id)

    if is_nil(contest_assessment) do
      changeset = change(%Assessment{}, %{number: ""})

      error_changeset =
        Ecto.Changeset.add_error(
          changeset,
          :number,
          "invalid contest number"
        )

      {:error, error_changeset}
    else
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

      voter_ids =
        CourseRegistration
        |> where(role: "student", course_id: ^course_id)
        |> select([cr], cr.id)
        |> Repo.all()

      votes_per_user = min(contest_submission_ids_length, 10)

      votes_per_submission =
        if Enum.empty?(contest_submission_ids) do
          0
        else
          trunc(Float.ceil(votes_per_user * length(voter_ids) / contest_submission_ids_length))
        end

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
              %SubmissionVotes{voter_id: voter_id, submission_id: s_id, question_id: question_id}
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
  end

  def update_assessment(id, params) when is_ecto_id(id) do
    simple_update(
      Assessment,
      id,
      using: &Assessment.changeset/2,
      params: params
    )
  end

  def update_question(id, params) when is_ecto_id(id) do
    simple_update(
      Question,
      id,
      using: &Question.changeset/2,
      params: params
    )
  end

  def publish_assessment(id) when is_ecto_id(id) do
    update_assessment(id, %{is_published: true})
  end

  def create_question_for_assessment(params, assessment_id) when is_ecto_id(assessment_id) do
    assessment =
      Assessment
      |> where(id: ^assessment_id)
      |> join(:left, [a], q in assoc(a, :questions))
      |> preload([_, q], questions: q)
      |> Repo.one()

    if assessment do
      params_with_assessment_id = Map.put_new(params, :assessment_id, assessment.id)

      %Question{}
      |> Question.changeset(params_with_assessment_id)
      |> put_display_order(assessment.questions)
      |> Repo.insert()
    else
      {:error, "Assessment not found"}
    end
  end

  def get_question(id) when is_ecto_id(id) do
    Question
    |> where(id: ^id)
    |> join(:inner, [q], assessment in assoc(q, :assessment))
    |> preload([_, a], assessment: a)
    |> Repo.one()
  end

  def delete_question(id) when is_ecto_id(id) do
    question = Repo.get(Question, id)
    Repo.delete(question)
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
    with {:ok, submission} <- find_or_create_submission(cr, question.assessment),
         {:status, true} <- {:status, force_submit or submission.status != :submitted},
         {:ok, _answer} <- insert_or_update_answer(submission, question, raw_answer, cr_id) do
      update_submission_status_router(submission, question)

      {:ok, nil}
    else
      {:status, _} ->
        {:error, {:forbidden, "Assessment submission already finalised"}}

      {:error, :race_condition} ->
        {:error, {:internal_server_error, "Please try again later."}}

      {:error, :vote_not_unique} ->
        {:error, {:bad_request, "Invalid vote or vote is not unique! Vote is not saved."}}

      _ ->
        {:error, {:bad_request, "Missing or invalid parameter(s)"}}
    end
  end

  def get_submission(assessment_id, %CourseRegistration{id: cr_id})
      when is_ecto_id(assessment_id) do
    Submission
    |> where(assessment_id: ^assessment_id)
    |> where(student_id: ^cr_id)
    |> join(:inner, [s], a in assoc(s, :assessment))
    |> preload([_, a], assessment: a)
    |> Repo.one()
  end

  def get_submission_by_id(submission_id) when is_ecto_id(submission_id) do
    Submission
    |> where(id: ^submission_id)
    |> join(:inner, [s], a in assoc(s, :assessment))
    |> preload([_, a], assessment: a)
    |> Repo.one()
  end

  def finalise_submission(submission = %Submission{}) do
    with {:status, :attempted} <- {:status, submission.status},
         {:ok, updated_submission} <- update_submission_status_and_xp_bonus(submission) do
      # Couple with update_submission_status_and_xp_bonus to ensure notification is sent
      Notifications.write_notification_when_student_submits(submission)
      # Send email notification to avenger
      %{notification_type: "assessment_submission", submission_id: updated_submission.id}
      |> Cadet.Workers.NotificationWorker.new()
      |> Oban.insert()

      # Begin autograding job
      GradingJob.force_grade_individual_submission(updated_submission)

      {:ok, nil}
    else
      {:status, :attempting} ->
        {:error, {:bad_request, "Some questions have not been attempted"}}

      {:status, :submitted} ->
        {:error, {:forbidden, "Assessment has already been submitted"}}

      _ ->
        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  def unsubmit_submission(
        submission_id,
        cr = %CourseRegistration{id: course_reg_id, role: role}
      )
      when is_ecto_id(submission_id) do
    submission =
      Submission
      |> join(:inner, [s], a in assoc(s, :assessment))
      |> preload([_, a], assessment: a)
      |> Repo.get(submission_id)

    # allows staff to unsubmit own assessment
    bypass = role in @bypass_closed_roles and submission.student_id == course_reg_id

    with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
         {:is_open?, true} <- {:is_open?, bypass or is_open?(submission.assessment)},
         {:status, :submitted} <- {:status, submission.status},
         {:allowed_to_unsubmit?, true} <-
           {:allowed_to_unsubmit?,
            role == :admin or bypass or
              Cadet.Accounts.Query.avenger_of?(cr, submission.student_id)} do
      Multi.new()
      |> Multi.run(
        :rollback_submission,
        fn _repo, _ ->
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
        Answer
        |> join(:inner, [a], q in assoc(a, :question))
        |> join(:inner, [a, _], s in assoc(a, :submission))
        |> preload([_, q, s], question: q, submission: s)
        |> where(submission_id: ^submission.id)
        |> Repo.all()
        |> Enum.reduce_while({:ok, nil}, fn answer, acc ->
          case acc do
            {:error, _} ->
              {:halt, acc}

            {:ok, _} ->
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

      Cadet.Accounts.Notifications.handle_unsubmit_notifications(
        submission.assessment.id,
        Repo.get(CourseRegistration, submission.student_id)
      )

      {:ok, nil}
    else
      {:submission_found?, false} ->
        {:error, {:not_found, "Submission not found"}}

      {:is_open?, false} ->
        {:error, {:forbidden, "Assessment not open"}}

      {:status, :attempting} ->
        {:error, {:bad_request, "Some questions have not been attempted"}}

      {:status, :attempted} ->
        {:error, {:bad_request, "Assessment has not been submitted"}}

      {:allowed_to_unsubmit?, false} ->
        {:error, {:forbidden, "Only Avenger of student or Admin is permitted to unsubmit"}}

      _ ->
        {:error, {:internal_server_error, "Please try again later."}}
    end
  end

  @spec update_submission_status_and_xp_bonus(Submission.t()) ::
          {:ok, Submission.t()} | {:error, Ecto.Changeset.t()}
  defp update_submission_status_and_xp_bonus(submission = %Submission{}) do
    assessment = submission.assessment
    assessment_conifg = Repo.get_by(AssessmentConfig, id: assessment.config_id)

    max_bonus_xp = assessment_conifg.early_submission_xp
    early_hours = assessment_conifg.hours_before_early_xp_decay

    xp_bonus =
      if Timex.before?(Timex.now(), Timex.shift(assessment.open_at, hours: early_hours)) do
        max_bonus_xp
      else
        # This logic interpolates from max bonus at early hour to 0 bonus at close time
        decaying_hours = Timex.diff(assessment.close_at, assessment.open_at, :hours) - early_hours
        remaining_hours = Enum.max([0, Timex.diff(assessment.close_at, Timex.now(), :hours)])
        proportion = if(decaying_hours > 0, do: remaining_hours / decaying_hours, else: 1)
        bonus_xp = round(max_bonus_xp * proportion)
        Enum.max([0, bonus_xp])
      end

    submission
    |> Submission.changeset(%{status: :submitted, xp_bonus: xp_bonus})
    |> Repo.update()
  end

  defp update_submission_status_router(submission = %Submission{}, question = %Question{}) do
    case question.type do
      :voting -> update_contest_voting_submission_status(submission, question)
      :mcq -> update_submission_status(submission, question.assessment)
      :programming -> update_submission_status(submission, question.assessment)
    end
  end

  defp update_submission_status(submission = %Submission{}, assessment = %Assessment{}) do
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
         assessment
       ) do
    Enum.map(
      questions,
      fn q ->
        if q.type == :voting do
          submission_votes = all_submission_votes_by_question_id_and_voter_id(q.id, voter_id)
          # fetch top 10 contest voting entries with the contest question id
          question_id = fetch_associated_contest_question_id(course_id, q)

          leaderboard_results =
            if is_nil(question_id) do
              []
            else
              if leaderboard_open?(assessment, q) or role in @open_all_assessment_roles do
                fetch_top_relative_score_answers(question_id, 10)
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

          Map.put(q, :question, voting_question)
        else
          q
        end
      end
    )
  end

  defp all_submission_votes_by_question_id_and_voter_id(question_id, voter_id) do
    SubmissionVotes
    |> where([v], v.voter_id == ^voter_id and v.question_id == ^question_id)
    |> join(:inner, [v], s in assoc(v, :submission))
    |> join(:inner, [v, s], a in assoc(s, :answers))
    |> select([v, s, a], %{submission_id: v.submission_id, answer: a.answer, score: v.score})
    |> Repo.all()
  end

  # Finds the contest_question_id associated with the given voting_question id
  defp fetch_associated_contest_question_id(course_id, voting_question) do
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

  @doc """
  Fetches top answers for the given question, based on the contest relative_score

  Used for contest leaderboard fetching
  """
  def fetch_top_relative_score_answers(question_id, number_of_answers) do
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
      student_name: student_user.name
    })
    |> limit(^number_of_answers)
    |> Repo.all()
  end

  @doc """
  Computes rolling leaderboard for contest votes that are still open.
  """
  def update_rolling_contest_leaderboards do
    # 115 = 2 hours - 5 minutes
    if Log.log_execution("update_rolling_contest_leaderboards", Timex.Duration.from_minutes(115)) do
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
    # 1435 = 24 hours - 5 minutes
    if Log.log_execution("update_final_contest_leaderboards", Timex.Duration.from_minutes(1435)) do
      Logger.info("Started update_final_contest_leaderboards")

      voting_questions_to_update = fetch_voting_questions_due_yesterday()

      _ =
        voting_questions_to_update
        |> Enum.map(fn qn -> compute_relative_score(qn.id) end)

      Logger.info("Successfully update_final_contest_leaderboards")
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
  Computes the current relative_score of each voting submission answer
  based on current submitted votes.
  """
  def compute_relative_score(contest_voting_question_id) do
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

    entry_scores = map_eligible_votes_to_entry_score(eligible_votes)

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
  end

  defp map_eligible_votes_to_entry_score(eligible_votes) do
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
        {ans_id, calculate_formula_score(sum_of_scores, number_of_voters, tokens)}
      end
    )
  end

  # Calculate the score based on formula
  # score(v,t) = v - 2^(t/50) where v is the normalized_voting_score
  # normalized_voting_score = sum_of_scores / number_of_voters / 10 * 100
  defp calculate_formula_score(sum_of_scores, number_of_voters, tokens) do
    normalized_voting_score = sum_of_scores / number_of_voters / 10 * 100
    normalized_voting_score - :math.pow(2, min(1023.5, tokens / 50))
  end

  @doc """
  Function returning submissions under a grader. This function returns only the
  fields that are exposed in the /grading endpoint. The reason we select only
  those fields is to reduce the memory usage especially when the number of
  submissions is large i.e. > 25000 submissions.

  The input parameters are the user and group_only. group_only is used to check
  whether only the groups under the grader should be returned. The parameter is
  a boolean which is false by default.

  The return value is {:ok, submissions} if no errors, else it is {:error,
  {:unauthorized, "Forbidden."}}
  """
  @spec all_submissions_by_grader_for_index(CourseRegistration.t()) ::
          {:ok, String.t()}
  def all_submissions_by_grader_for_index(
        grader = %CourseRegistration{course_id: course_id},
        group_only \\ false,
        ungraded_only \\ false
      ) do
    show_all = not group_only

    group_where =
      if show_all,
        do: "",
        else:
          "where s.student_id in (select cr.id from course_registrations cr inner join groups g on cr.group_id = g.id where g.leader_id = $2) or s.student_id = $2"

    ungraded_where =
      if ungraded_only,
        do: "where s.\"gradedCount\" < assts.\"questionCount\"",
        else: ""

    params = if show_all, do: [course_id], else: [course_id, grader.id]

    # We bypass Ecto here and use a raw query to generate JSON directly from
    # PostgreSQL, because doing it in Elixir/Erlang is too inefficient.

    case Repo.query(
           """
           select json_agg(q)::TEXT from
           (
             select
               s.id,
               s.status,
               s."unsubmittedAt",
               s.xp,
               s."xpAdjustment",
               s."xpBonus",
               s."gradedCount",
               assts.jsn as assessment,
               students.jsn as student,
               unsubmitters.jsn as "unsubmittedBy"
             from
               (select
                 s.id,
                 s.student_id,
                 s.assessment_id,
                 s.status,
                 s.unsubmitted_at as "unsubmittedAt",
                 s.unsubmitted_by_id,
                 sum(ans.xp) as xp,
                 sum(ans.xp_adjustment) as "xpAdjustment",
                 s.xp_bonus as "xpBonus",
                 count(ans.id) filter (where ans.grader_id is not null) as "gradedCount"
               from submissions s
                 left join
                 answers ans on s.id = ans.submission_id
               #{group_where}
               group by s.id) s
             inner join
               (select
                 a.id, a."questionCount", to_json(a) as jsn
               from
                 (select
                   a.id,
                   a.title,
                   bool_or(ac.is_manually_graded) as "isManuallyGraded",
                   max(ac.type) as "type",
                   sum(q.max_xp) as "maxXp",
                   count(q.id) as "questionCount"
                 from assessments a
                   left join
                   questions q on a.id = q.assessment_id
                   inner join
                   assessment_configs ac on ac.id = a.config_id
                  where a.course_id = $1
                 group by a.id) a) assts on assts.id = s.assessment_id
             inner join
               (select
                 cr.id, to_json(cr) as jsn
               from
                 (select
                   cr.id,
                   u.name as "name",
                   g.name as "groupName",
                   g.leader_id as "groupLeaderId"
                 from course_registrations cr
                   left join
                   groups g on g.id = cr.group_id
                   inner join
                   users u on u.id = cr.user_id) cr) students on students.id = s.student_id
             left join
               (select
                 cr.id, to_json(cr) as jsn
               from
                 (select
                   cr.id,
                   u.name
                 from course_registrations cr
                   inner join
                   users u on u.id = cr.user_id) cr) unsubmitters on s.unsubmitted_by_id = unsubmitters.id
             #{ungraded_where}
           ) q
           """,
           params
         ) do
      {:ok, %{rows: [[nil]]}} -> {:ok, "[]"}
      {:ok, %{rows: [[json]]}} -> {:ok, json}
    end
  end

  @spec get_answers_in_submission(integer() | String.t()) ::
          {:ok, [Answer.t()]} | {:error, {:bad_request | :unauthorized, String.t()}}
  def get_answers_in_submission(id) when is_ecto_id(id) do
    answer_query =
      Answer
      |> where(submission_id: ^id)
      |> join(:inner, [a], q in assoc(a, :question))
      |> join(:inner, [_, q], ast in assoc(q, :assessment))
      |> join(:inner, [a, ..., ast], ac in assoc(ast, :config))
      |> join(:left, [a, ...], g in assoc(a, :grader))
      |> join(:left, [a, ..., g], gu in assoc(g, :user))
      |> join(:inner, [a, ...], s in assoc(a, :submission))
      |> join(:inner, [a, ..., s], st in assoc(s, :student))
      |> join(:inner, [a, ..., st], u in assoc(st, :user))
      |> preload([_, q, ast, ac, g, gu, s, st, u],
        question: {q, assessment: {ast, config: ac}},
        grader: {g, user: gu},
        submission: {s, student: {st, user: u}}
      )

    answers =
      answer_query
      |> Repo.all()
      |> Enum.sort_by(& &1.question.display_order)
      |> Enum.map(fn ans ->
        if ans.question.type == :voting do
          empty_contest_entries = Map.put(ans.question.question, :contest_entries, [])
          empty_contest_leaderboard = Map.put(empty_contest_entries, :contest_leaderboard, [])
          question = Map.put(ans.question, :question, empty_contest_leaderboard)
          Map.put(ans, :question, question)
        else
          ans
        end
      end)

    if answers == [] do
      {:error, {:bad_request, "Submission is not found."}}
    else
      {:ok, answers}
    end
  end

  defp is_fully_graded?(%Answer{submission_id: submission_id}) do
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

  @spec update_grading_info(
          %{submission_id: integer() | String.t(), question_id: integer() | String.t()},
          %{},
          CourseRegistration.t()
        ) ::
          {:ok, nil}
          | {:error, {:unauthorized | :bad_request | :internal_server_error, String.t()}}
  def update_grading_info(
        %{submission_id: submission_id, question_id: question_id},
        attrs,
        %CourseRegistration{id: grader_id}
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

    with {:answer_found?, true} <- {:answer_found?, is_map(answer)},
         {:status, true} <-
           {:status, answer.submission.status == :submitted or is_own_submission},
         {:valid, changeset = %Ecto.Changeset{valid?: true}} <-
           {:valid, Answer.grading_changeset(answer, attrs)},
         {:ok, _} <- Repo.update(changeset) do
      if is_fully_graded?(answer) and not is_own_submission do
        # Every answer in this submission has been graded manually
        Notifications.write_notification_when_graded(submission_id, :graded)
      else
        {:ok, nil}
      end
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
    {:error, {:unauthorized, "User is not permitted to grade."}}
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
    submission =
      Submission
      |> where(student_id: ^cr.id)
      |> where(assessment_id: ^assessment.id)
      |> Repo.one()

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
    %Submission{}
    |> Submission.changeset(%{student: cr, assessment: assessment})
    |> Repo.insert()
    |> case do
      {:ok, submission} -> {:ok, submission}
      {:error, _} -> {:error, :race_condition}
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
          type: question.type
        })

      Repo.insert(
        answer_changeset,
        on_conflict: [set: [answer: get_change(answer_changeset, :answer)]],
        conflict_target: [:submission_id, :question_id]
      )
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
      {:error, _name, _changset, _error} -> {:error, :vote_not_unique}
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
end
