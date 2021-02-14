defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Accounts.{Notification, Notifications, User}
  alias Cadet.Assessments.{Answer, Assessment, Query, Question, Submission, SubmissionVotes}
  alias Cadet.Autograder.GradingJob
  alias Cadet.Course.Group
  alias Ecto.Multi

  require Decimal

  @xp_early_submission_max_bonus 100
  @xp_bonus_assessment_type ~w(mission sidequest)
  # @submit_answer_roles ~w(student staff admin)a
  @change_dates_assessment_role ~w(staff admin)a
  @delete_assessment_role ~w(staff admin)a
  @publish_assessment_role ~w(staff admin)a
  @unsubmit_assessment_role ~w(staff admin)a
  @see_all_submissions_roles ~w(staff admin)a
  @group_grading_summary_roles @see_all_submissions_roles
  @open_all_assessment_roles ~w(staff admin)a

  # These roles can save and finalise answers for closed assessments and
  # submitted answers
  @bypass_closed_roles ~w(staff admin)a

  def change_dates_assessment(_user = %User{role: role}, id, close_at, open_at) do
    if role in @change_dates_assessment_role do
      if Timex.before?(close_at, open_at) do
        {:error, {:bad_request, "New end date should occur after new opening date"}}
      else
        update_assessment(id, %{close_at: close_at, open_at: open_at})
      end
    else
      {:error, {:forbidden, "User is not permitted to edit"}}
    end
  end

  def toggle_publish_assessment(_publisher = %User{role: role}, id) do
    if role in @publish_assessment_role do
      assessment = Repo.get(Assessment, id)
      update_assessment(id, %{is_published: !assessment.is_published})
    else
      {:error, {:forbidden, "User is not permitted to publish"}}
    end
  end

  def delete_assessment(_deleter = %User{role: role}, id) do
    if role in @delete_assessment_role do
      assessment = Repo.get(Assessment, id)

      Submission
      |> where(assessment_id: ^id)
      |> delete_submission_assocation(id)

      SubmissionVotes
      |> where(assessment_id: ^id)
      |> Repo.delete_all()

      Repo.delete(assessment)
    else
      {:error, {:forbidden, "User is not permitted to delete"}}
    end
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

  @spec user_max_grade(%User{}) :: integer()
  def user_max_grade(%User{id: user_id}) when is_ecto_id(user_id) do
    Submission
    |> where(status: ^:submitted)
    |> where(student_id: ^user_id)
    |> join(
      :inner,
      [s],
      a in subquery(Query.all_assessments_with_max_grade()),
      on: s.assessment_id == a.id
    )
    |> select([_, a], sum(a.max_grade))
    |> Repo.one()
    |> decimal_to_integer()
  end

  def user_total_grade_xp(%User{id: user_id}) do
    submission_grade_xp =
      Submission
      |> where(student_id: ^user_id)
      |> join(:inner, [s], a in Answer, on: s.id == a.submission_id)
      |> group_by([s], s.id)
      |> select([s, a], %{
        total_grade: sum(a.grade) + sum(a.adjustment),
        # grouping by submission, so s.xp_bonus will be the same, but we need an
        # aggregate function
        total_xp: sum(a.xp) + sum(a.xp_adjustment) + max(s.xp_bonus)
      })

    total =
      submission_grade_xp
      |> subquery
      |> select([s], %{
        total_grade: sum(s.total_grade),
        total_xp: sum(s.total_xp)
      })
      |> Repo.one()

    for {key, val} <- total, into: %{}, do: {key, decimal_to_integer(val)}
  end

  defp decimal_to_integer(decimal) do
    if Decimal.is_decimal(decimal) do
      Decimal.to_integer(decimal)
    else
      0
    end
  end

  def user_with_group(%User{id: id}) do
    User
    |> preload(:group)
    |> Repo.get(id)
  end

  def user_current_story(user = %User{}) do
    {:ok, %{result: story}} =
      Multi.new()
      |> Multi.run(:unattempted, fn _repo, _ ->
        {:ok, get_user_story_by_type(user, :unattempted)}
      end)
      |> Multi.run(:result, fn _repo, %{unattempted: unattempted_story} ->
        if unattempted_story do
          {:ok, %{play_story?: true, story: unattempted_story}}
        else
          {:ok, %{play_story?: false, story: get_user_story_by_type(user, :attempted)}}
        end
      end)
      |> Repo.transaction()

    story
  end

  @spec get_user_story_by_type(%User{}, :unattempted | :attempted) :: String.t() | nil
  def get_user_story_by_type(%User{id: user_id}, type)
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
    |> join(:left, [a], s in Submission, on: s.assessment_id == a.id and s.student_id == ^user_id)
    |> filter_and_sort.()
    |> order_by([a], a.type)
    |> select([a], a.story)
    |> first()
    |> Repo.one()
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{password: nil},
        user = %User{},
        nil
      ) do
    assessment_with_questions_and_answers(assessment, user)
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{password: nil},
        user = %User{},
        _
      ) do
    assessment_with_questions_and_answers(assessment, user)
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{password: password},
        user = %User{},
        given_password
      ) do
    cond do
      Timex.after?(Timex.now(), assessment.close_at) ->
        assessment_with_questions_and_answers(assessment, user)

      match?({:ok, _}, find_submission(user, assessment)) ->
        assessment_with_questions_and_answers(assessment, user)

      given_password == nil ->
        {:error, {:forbidden, "Missing Password."}}

      password == given_password ->
        find_or_create_submission(user, assessment)
        assessment_with_questions_and_answers(assessment, user)

      true ->
        {:error, {:forbidden, "Invalid Password."}}
    end
  end

  def assessment_with_questions_and_answers(id, user = %User{}, password)
      when is_ecto_id(id) do
    role = user.role

    assessment =
      if role in @open_all_assessment_roles do
        Assessment
        |> where(id: ^id)
        |> Repo.one()
      else
        Assessment
        |> where(id: ^id)
        |> where(is_published: true)
        |> Repo.one()
      end

    if assessment do
      assessment_with_questions_and_answers(assessment, user, password)
    else
      {:error, {:bad_request, "Assessment not found"}}
    end
  end

  def assessment_with_questions_and_answers(
        assessment = %Assessment{id: id},
        user = %User{role: role}
      ) do
    if Timex.after?(Timex.now(), assessment.open_at) or role in @open_all_assessment_roles do
      answer_query =
        Answer
        |> join(:inner, [a], s in assoc(a, :submission))
        |> where([_, s], s.student_id == ^user.id)

      questions =
        Question
        |> where(assessment_id: ^id)
        |> join(:left, [q], a in subquery(answer_query), on: q.id == a.question_id)
        |> join(:left, [_, a], g in assoc(a, :grader))
        |> select([q, a, g], {q, a, g})
        |> order_by(:display_order)
        |> Repo.all()
        |> Enum.map(fn
          {q, nil, _} -> %{q | answer: %Answer{grader: nil}}
          {q, a, g} -> %{q | answer: %Answer{a | grader: g}}
        end)

      assessment = Map.put(assessment, :questions, questions)
      {:ok, assessment}
    else
      {:error, {:unauthorized, "Assessment not open"}}
    end
  end

  def assessment_with_questions_and_answers(id, user = %User{}) do
    assessment_with_questions_and_answers(id, user, nil)
  end

  @doc """
  Returns a list of assessments with all fields and an indicator showing whether it has been attempted
  by the supplied user
  """
  def all_assessments(user = %User{}) do
    submission_aggregates =
      Submission
      |> join(:left, [s], ans in Answer, on: ans.submission_id == s.id)
      |> where([s], s.student_id == ^user.id)
      |> group_by([s], s.assessment_id)
      |> select([s, ans], %{
        assessment_id: s.assessment_id,
        grade: fragment("? + ?", sum(ans.grade), sum(ans.adjustment)),
        # s.xp_bonus should be the same across the group, but we need an aggregate function here
        xp: fragment("? + ? + ?", sum(ans.xp), sum(ans.xp_adjustment), max(s.xp_bonus)),
        graded_count: ans.id |> count() |> filter(not is_nil(ans.grader_id))
      })

    submission_status =
      Submission
      |> where([s], s.student_id == ^user.id)
      |> select([s], [:assessment_id, :status])

    assessments =
      Query.all_assessments_with_aggregates()
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
          grade: sa.grade,
          graded_count: sa.graded_count,
          user_status: s.status
      })
      |> filter_published_assessments(user)
      |> order_by(:open_at)
      |> Repo.all()

    {:ok, assessments}
  end

  def filter_published_assessments(assessments, user) do
    role = user.role

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
            question_params
            |> Map.put(:display_order, index)
            |> build_question_changeset_for_assessment_id(id)
            |> Repo.insert()
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
      if Timex.after?(open_date, Timex.now()) do
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
  defp insert_or_update_assessment_changeset(params = %{number: number}, force_update) do
    Assessment
    |> where(number: ^number)
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

  def insert_voting(voting_params, assessment_id) do
    changesets =
      Enum.map(voting_params, fn voting_entry ->
        build_voting_submission_changeset_for_assessment_id(voting_entry.voting, assessment_id)
      end)

    changesets
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {changeset, index}, multi ->
      Multi.insert(multi, Integer.to_string(index), changeset)
    end)
    |> Repo.transaction()
  end

  defp build_voting_submission_changeset_for_assessment_id(params, assessment_id)
       when is_ecto_id(assessment_id) do
    params_with_assessment_id = Map.put_new(params, :assessment_id, assessment_id)
    SubmissionVotes.changeset(%SubmissionVotes{}, params_with_assessment_id)
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

  def publish_assessment(id) do
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
  def answer_question(id, user = %User{role: role}, raw_answer) when is_ecto_id(id) do
    # if role in @submit_answer_roles do
    question =
      Question
      |> where(id: ^id)
      |> join(:inner, [q], assessment in assoc(q, :assessment))
      |> preload([_, a], assessment: a)
      |> Repo.one()

    bypass = role in @bypass_closed_roles

    with {:question_found?, true} <- {:question_found?, is_map(question)},
         {:is_open?, true} <- {:is_open?, bypass or is_open?(question.assessment)},
         {:ok, submission} <- find_or_create_submission(user, question.assessment),
         {:status, true} <- {:status, bypass or submission.status != :submitted},
         {:ok, _answer} <- insert_or_update_answer(submission, question, raw_answer) do
      update_submission_status(submission, question.assessment)

      {:ok, nil}
    else
      {:question_found?, false} -> {:error, {:not_found, "Question not found"}}
      {:is_open?, false} -> {:error, {:forbidden, "Assessment not open"}}
      {:status, _} -> {:error, {:forbidden, "Assessment submission already finalised"}}
      {:error, :race_condition} -> {:error, {:internal_server_error, "Please try again later."}}
      _ -> {:error, {:bad_request, "Missing or invalid parameter(s)"}}
    end

    # else
    #  {:error, {:forbidden, "User is not permitted to answer questions"}}
    # end
  end

  def finalise_submission(assessment_id, %User{id: user_id, role: role})
      when is_ecto_id(assessment_id) do
    # if role in @submit_answer_roles do
    submission =
      Submission
      |> where(assessment_id: ^assessment_id)
      |> where(student_id: ^user_id)
      |> join(:inner, [s], a in assoc(s, :assessment))
      |> preload([_, a], assessment: a)
      |> Repo.one()

    with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
         {:is_open?, true} <-
           {:is_open?, role in @bypass_closed_roles or is_open?(submission.assessment)},
         {:status, :attempted} <- {:status, submission.status},
         {:ok, updated_submission} <- update_submission_status_and_xp_bonus(submission) do
      # TODO: Couple with update_submission_status_and_xp_bonus to ensure notification is sent
      Notifications.write_notification_when_student_submits(submission)
      # Begin autograding job
      GradingJob.force_grade_individual_submission(updated_submission)

      {:ok, nil}
    else
      {:submission_found?, false} ->
        {:error, {:not_found, "Submission not found"}}

      {:is_open?, false} ->
        {:error, {:forbidden, "Assessment not open"}}

      {:status, :attempting} ->
        {:error, {:bad_request, "Some questions have not been attempted"}}

      {:status, :submitted} ->
        {:error, {:forbidden, "Assessment has already been submitted"}}

      _ ->
        {:error, {:internal_server_error, "Please try again later."}}
    end

    # else
    #   {:error, {:forbidden, "User is not permitted to answer questions"}}
    # end
  end

  def unsubmit_submission(submission_id, user = %User{id: user_id, role: role})
      when is_ecto_id(submission_id) do
    if role in @unsubmit_assessment_role do
      submission =
        Submission
        |> join(:inner, [s], a in assoc(s, :assessment))
        |> preload([_, a], assessment: a)
        |> Repo.get(submission_id)

      bypass = role in @bypass_closed_roles and submission.student_id == user_id

      with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
           {:is_open?, true} <- {:is_open?, bypass or is_open?(submission.assessment)},
           {:status, :submitted} <- {:status, submission.status},
           {:allowed_to_unsubmit?, true} <-
             {:allowed_to_unsubmit?,
              role == :admin or bypass or
                Cadet.Accounts.Query.avenger_of?(user, submission.student_id)} do
        Multi.new()
        |> Multi.run(
          :rollback_submission,
          fn _repo, _ ->
            submission
            |> Submission.changeset(%{
              status: :attempted,
              xp_bonus: 0,
              unsubmitted_by_id: user_id,
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
                   grade: 0,
                   adjustment: 0,
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
          Cadet.Accounts.get_user(submission.student_id)
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
    else
      {:error, {:forbidden, "User is not permitted to unsubmit questions"}}
    end
  end

  @spec update_submission_status_and_xp_bonus(%Submission{}) ::
          {:ok, %Submission{}} | {:error, Ecto.Changeset.t()}
  defp update_submission_status_and_xp_bonus(submission = %Submission{}) do
    assessment = submission.assessment

    xp_bonus =
      cond do
        assessment.type not in @xp_bonus_assessment_type ->
          0

        Timex.before?(Timex.now(), Timex.shift(assessment.open_at, hours: 48)) ->
          @xp_early_submission_max_bonus

        true ->
          deduction = Timex.diff(Timex.now(), assessment.open_at, :hours) - 48
          Enum.max([0, @xp_early_submission_max_bonus - deduction])
      end

    submission
    |> Submission.changeset(%{status: :submitted, xp_bonus: xp_bonus})
    |> Repo.update()
  end

  def update_submission_status(submission = %Submission{}, assessment = %Assessment{}) do
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

  @doc """
  Function returning contest submission entries assigned to a user to vote for. 
  """
  # @spec all_submission_votes_by_assessment_id_and_user_id() :: 
  #       {:ok, String.t()} 
  def all_submission_votes_by_assessment_id_and_user_id(assessment_id, user_id) do
    query =
      from(sv in SubmissionVotes,
        where: sv.user_id == ^user_id,
        where: sv.assessment_id == ^assessment_id,
        join: s in assoc(sv, :submission),
        join: ans in assoc(s, :answers),
        select: %{submission_id: sv.submission_id, answer: ans.answer, score: sv.score}
      )

    submission_votes = Repo.all(query)
    {:ok, submission_votes}
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
  {:unauthorized, "User is not permitted to grade."}}
  """
  @spec all_submissions_by_grader_for_index(%User{}) ::
          {:ok, String.t()} | {:error, {:unauthorized, String.t()}}
  def all_submissions_by_grader_for_index(grader = %User{role: role}, group_only \\ false) do
    if role in @see_all_submissions_roles do
      show_all = role in @see_all_submissions_roles and not group_only

      group_where =
        if show_all,
          do: "",
          else:
            "where s.student_id in (select u.id from users u inner join groups g on u.group_id = g.id where g.leader_id = $1) or s.student_id = $1"

      params = if show_all, do: [], else: [grader.id]

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
                 s.grade,
                 s.adjustment,
                 s.xp,
                 s."xpAdjustment",
                 s."xpBonus",
                 s."gradedCount",
                 assts.jsn AS assessment,
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
                   sum(ans.grade) as grade,
                   sum(ans.adjustment) as adjustment,
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
                   a.id, to_json(a) as jsn
                 from (select a.id, a.title, a.type, sum(q.max_grade) as "maxGrade", sum(q.max_xp) as "maxXp", count(q.id) as "questionCount" from assessments a left join questions q on a.id = q.assessment_id group by a.id) a) assts on assts.id = s.assessment_id
               inner join
                 (select u.id, to_json(u) as jsn from (select u.id, u.name, g.name as "groupName", g.leader_id as "groupLeaderId" from users u left join groups g on g.id = u.group_id) u) students on students.id = s.student_id
               left join
                 (select u.id, to_json(u) as jsn from (select u.id, u.name from users u) u) unsubmitters on s.unsubmitted_by_id = unsubmitters.id
             ) q
             """,
             params
           ) do
        {:ok, %{rows: [[nil]]}} -> {:ok, "[]"}
        {:ok, %{rows: [[json]]}} -> {:ok, json}
      end
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
    end
  end

  @spec get_answers_in_submission(integer() | String.t(), %User{}) ::
          {:ok, [%Answer{}]} | {:error, {:unauthorized, String.t()}}
  def get_answers_in_submission(id, %User{role: role}) when is_ecto_id(id) do
    answer_query =
      Answer
      |> where(submission_id: ^id)
      |> join(:inner, [a], q in assoc(a, :question))
      |> join(:inner, [_, q], ast in assoc(q, :assessment))
      |> join(:left, [a, ...], g in assoc(a, :grader))
      |> join(:inner, [a, ...], s in assoc(a, :submission))
      |> join(:inner, [a, ..., s], st in assoc(s, :student))
      |> preload([_, q, ast, g, s, st],
        question: {q, assessment: ast},
        grader: g,
        submission: {s, student: st}
      )

    if role in @see_all_submissions_roles do
      answers =
        answer_query
        |> Repo.all()
        |> Enum.sort_by(& &1.question.display_order)

      {:ok, answers}
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
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
          %User{}
        ) ::
          {:ok, nil}
          | {:error, {:unauthorized | :bad_request | :internal_server_error, String.t()}}
  def update_grading_info(
        %{submission_id: submission_id, question_id: question_id},
        attrs,
        %User{id: grader_id, role: role}
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) and
             role in @see_all_submissions_roles do
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

  @spec force_regrade_submission(integer() | String.t(), %User{}) ::
          {:ok, nil} | {:error, {:forbidden | :not_found, String.t()}}
  def force_regrade_submission(submission_id, _requesting_user = %User{id: grader_id, role: role})
      when is_ecto_id(submission_id) and role in @see_all_submissions_roles do
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

  @spec force_regrade_answer(integer() | String.t(), integer() | String.t(), %User{}) ::
          {:ok, nil} | {:error, {:forbidden | :not_found, String.t()}}
  def force_regrade_answer(
        submission_id,
        question_id,
        _requesting_user = %User{id: grader_id, role: role}
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) and
             role in @see_all_submissions_roles do
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

  defp find_submission(user = %User{}, assessment = %Assessment{}) do
    submission =
      Submission
      |> where(student_id: ^user.id)
      |> where(assessment_id: ^assessment.id)
      |> Repo.one()

    if submission do
      {:ok, submission}
    else
      {:error, nil}
    end
  end

  # Checks if an assessment is open and published.
  @spec is_open?(%Assessment{}) :: boolean()
  defp is_open?(%Assessment{open_at: open_at, close_at: close_at, is_published: is_published}) do
    Timex.between?(Timex.now(), open_at, close_at) and is_published
  end

  @type group_summary_entry :: %{
          group_name: String.t(),
          leader_name: String.t(),
          ungraded_missions: integer(),
          submitted_missions: integer(),
          ungraded_sidequests: number(),
          submitted_sidequests: number()
        }

  @spec get_group_grading_summary(%User{}) ::
          {:ok, [group_summary_entry()]} | {:error, {atom(), String.t()}}
  def get_group_grading_summary(%User{role: role}) do
    if role in @group_grading_summary_roles do
      subs =
        Answer
        |> join(:left, [ans], s in Submission, on: s.id == ans.submission_id)
        |> join(:left, [ans, s], st in User, on: s.student_id == st.id)
        |> join(:left, [ans, s, st], a in Assessment, on: a.id == s.assessment_id)
        |> where(
          [ans, s, st, a],
          not is_nil(st.group_id) and s.status == ^:submitted and
            a.type in ^["mission", "sidequest"]
        )
        |> group_by([ans, s, st, a], s.id)
        |> select([ans, s, st, a], %{
          group_id: max(st.group_id),
          type: max(a.type),
          num_submitted: count(),
          num_ungraded: filter(count(), is_nil(ans.grader_id))
        })

      rows =
        subs
        |> subquery()
        |> join(:left, [t], g in Group, on: t.group_id == g.id)
        |> join(:left, [t, g], l in User, on: l.id == g.leader_id)
        |> group_by([t, g, l], [t.group_id, g.name, l.name])
        |> select([t, g, l], %{
          group_name: g.name,
          leader_name: l.name,
          ungraded_missions: filter(count(), t.type == "mission" and t.num_ungraded > 0),
          submitted_missions: filter(count(), t.type == "mission"),
          ungraded_sidequests: filter(count(), t.type == "sidequest" and t.num_ungraded > 0),
          submitted_sidequests: filter(count(), t.type == "sidequest")
        })
        |> Repo.all()

      {:ok, rows}
    else
      {:error, {:unauthorized, "User is not permitted to view the grading summary."}}
    end
  end

  defp create_empty_submission(user = %User{}, assessment = %Assessment{}) do
    %Submission{}
    |> Submission.changeset(%{student: user, assessment: assessment})
    |> Repo.insert()
    |> case do
      {:ok, submission} -> {:ok, submission}
      {:error, _} -> {:error, :race_condition}
    end
  end

  defp find_or_create_submission(user = %User{}, assessment = %Assessment{}) do
    case find_submission(user, assessment) do
      {:ok, submission} -> {:ok, submission}
      {:error, _} -> create_empty_submission(user, assessment)
    end
  end

  defp insert_or_update_answer(submission = %Submission{}, question = %Question{}, raw_answer) do
    answer_content = build_answer_content(raw_answer, question.type)

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

  defp build_answer_content(raw_answer, question_type) do
    case question_type do
      :mcq ->
        %{choice_id: raw_answer}

      :programming ->
        %{code: raw_answer}
    end
  end
end
