defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Accounts.{Notifications, User}
  alias Cadet.Assessments.{Answer, Assessment, Query, Question, Submission}
  alias Cadet.Autograder.GradingJob
  alias Cadet.Chat.Room
  alias Ecto.Multi

  @xp_early_submission_max_bonus 100
  @xp_bonus_assessment_type ~w(mission sidequest)a
  @submit_answer_roles ~w(student)a
  @change_dates_assessment_role ~w(staff admin)a
  @delete_assessment_role ~w(staff admin)a
  @publish_assessment_role ~w(staff admin)a
  @unsubmit_assessment_role ~w(staff admin)a
  @grading_roles ~w()a
  @see_all_submissions_roles ~w(staff admin)a
  @open_all_assessment_roles ~w(staff admin)a

  def change_dates_assessment(_user = %User{role: role}, id, close_at, open_at) do
    if role in @change_dates_assessment_role do
      assessment = Repo.get(Assessment, id)
      previous_open_time = assessment.open_at
      cond do
        Timex.before?(close_at, open_at) -> 
          {:error, {:bad_request, "New end date should occur after new opening date"}}

        Timex.before?(close_at, Timex.now()) ->
          {:error, {:bad_request, "New end date should occur after current time"}}

        Timex.equal?(previous_open_time, open_at) or Timex.after?(previous_open_time, Timex.now()) ->
          update_assessment(id, %{close_at: close_at, open_at: open_at})

        Timex.before?(open_at, Timex.now()) ->
          {:error, {:bad_request, "New Opening date should occur after current time"}}
        
        true ->
          {:error, {:forbidden, "Assessment is already opened"}}
      end
    else
      {:error, {:forbidden, "User is not permitted to edit"}}
    end
  end

  def toggle_publish_assessment(_publisher = %User{role: role}, id, bool) do
    if role in @publish_assessment_role do
      update_assessment(id, %{is_published: bool})
    else
      {:error, {:forbidden, "User is not permitted to publish"}}
    end
  end

  def delete_assessment(_deleter = %User{role: role}, id) do
    if role in @delete_assessment_role do
      assessment = Repo.get(Assessment, id)
      Repo.delete(assessment)
    else
      {:error, {:forbidden, "User is not permitted to delete"}}
    end
  end

  @spec user_total_xp(%User{}) :: integer()
  def user_total_xp(%User{id: user_id}) when is_ecto_id(user_id) do
    total_xp_bonus =
      Submission
      |> where(student_id: ^user_id)
      |> Repo.aggregate(:sum, :xp_bonus)
      |> case do
        nil -> 0
        xp when is_integer(xp) -> xp
      end

    total_xp =
      Query.all_submissions_with_xp()
      |> subquery()
      |> where(student_id: ^user_id)
      |> select([q], fragment("? + ?", sum(q.xp), sum(q.xp_adjustment)))
      |> Repo.one()
      |> decimal_to_integer()

    total_xp_bonus + total_xp
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

  def user_total_grade(%User{id: user_id}) do
    Query.all_submissions_with_grade()
    |> subquery()
    |> where(student_id: ^user_id)
    |> select([q], fragment("? + ?", sum(q.grade), sum(q.adjustment)))
    |> Repo.one()
    |> decimal_to_integer()
  end

  defp decimal_to_integer(decimal) do
    if Decimal.decimal?(decimal) do
      Decimal.to_integer(decimal)
    else
      0
    end
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
        |> select([q, a, g], %{q | answer: %Answer{a | grader: g}})
        |> order_by(:display_order)
        |> Repo.all()

      assessment = Map.put(assessment, :questions, questions)
      {:ok, assessment}
    else
      {:error, {:unauthorized, "Assessment not open"}}
    end
  end

  def assessment_with_questions_and_answers(id, user = %User{}) do
    assessment_with_questions_and_answers(id, user, nil)
  end

  def all_assessments(user = %User{}) do
    assessments =
      Query.all_assessments_with_max_xp_and_grade()
      |> subquery()
      |> join(
        :left,
        [a],
        s in subquery(Query.all_submissions_with_xp_and_grade()),
        on: a.id == s.assessment_id and s.student_id == ^user.id
      )
      |> join(
        :left,
        [a, _],
        q_count in subquery(Query.assessments_question_count()),
        on: a.id == q_count.assessment_id
      )
      |> join(
        :left,
        [_, s, _],
        a_count in subquery(Query.submissions_graded_count()),
        on: s.id == a_count.submission_id
      )
      |> select([a, s, q_count, a_count], %{
        a
        | xp: fragment("? + ? + ?", s.xp, s.xp_adjustment, s.xp_bonus),
          grade: fragment("? + ?", s.grade, s.adjustment),
          user_status: s.status,
          question_count: q_count.count,
          graded_count: a_count.count
      })
      |> filter_published_assessments(user)
      |> order_by(:open_at)
      |> Repo.all()
      |> Enum.map(fn assessment = %Assessment{} ->
        %{
          assessment
          | grading_status:
              build_grading_status(
                assessment.user_status,
                assessment.type,
                assessment.question_count,
                assessment.graded_count
              )
        }
      end)

    {:ok, assessments}
  end

  def filter_published_assessments(assessments, user) do 
    role = user.role
    case role do
      :student -> where(assessments, is_published: true)
      _ -> assessments
    end
  end

  defp build_grading_status(submission_status, a_type, q_count, g_count) do
    case a_type do
      type when type in [:mission, :sidequest] ->
        cond do
          submission_status != :submitted -> :excluded
          g_count < q_count -> :grading
          g_count == q_count -> :graded
          true -> :none
        end

      _ ->
        :excluded
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
  def insert_or_update_assessments_and_questions(assessment_params, questions_params, force_update) do
    assessment_multi =
      Multi.insert_or_update(
        Multi.new(),
        :assessment,
        insert_or_update_assessment_changeset(assessment_params, force_update)
      )

    if force_update and check_question_count(assessment_multi, questions_params) do
      {:error, "Question count is different"}
    else
      questions_params
      |> Enum.with_index(1)
      |> Enum.reduce(assessment_multi, fn {question_params, index}, multi ->
        Multi.run(multi, String.to_atom("question#{index}"), fn _repo,
                                                                %{assessment: %Assessment{id: id}} ->
          question_exists = 
            Repo.exists?(where(Question, [q], q.assessment_id == ^id and q.display_order == ^index))
          if !force_update or !question_exists do 
            question_params
            |> Map.put(:display_order, index)
            |> build_question_changeset_for_assessment_id(id)
            |> Repo.insert()
          else
            params = 
              (if !question_params.max_xp do 
                question_params
                |> Map.put(:max_xp, 0)
              else
                question_params
              end)
              |> Map.put(:display_order, index)

            %{id: question_id} = 
              where(Question, [q], q.display_order == ^index and q.assessment_id == ^id)
              |> Repo.one()

            changeset = Question.changeset(%Question{assessment_id: id, id: question_id}, params)
            Repo.update(changeset)
          end
        end)
      end)
      |> Repo.transaction()
    end
  end

  defp check_question_count(assessment_multi, questions_params) do
    assessment_id =
      (assessment_multi.operations
      |> List.first()
      |> elem(1)
      |> elem(1)).data.id

    if !assessment_id do 
      false 
    else
      existing_questions_count = 
      where(Question, [q], q.assessment_id == ^assessment_id)
      |> Repo.all()
      |> Enum.count

      new_questions_count = Enum.count(questions_params)

      existing_questions_count != new_questions_count
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
      assessment ->
        cond do
          Timex.after?(assessment.open_at, Timex.now()) ->
            # Delete all existing questions
            %{id: assessment_id} = assessment

            Question
            |> where(assessment_id: ^assessment_id)
            |> Repo.delete_all()

            Assessment.changeset(assessment, params)

          force_update ->
            # Maintain the same open/close date when force updating an assessment
            new_params = 
              params
              |> Map.delete(:open_at)
              |> Map.delete(:close_at)

            Assessment.changeset(assessment, new_params)

          true ->
            # if the assessment is already open, don't mess with it
            create_invalid_changeset_with_error(:assessment, "is already open")
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
    if role in @submit_answer_roles do
      question =
        Question
        |> where(id: ^id)
        |> join(:inner, [q], assessment in assoc(q, :assessment))
        |> preload([_, a], assessment: a)
        |> Repo.one()

      with {:question_found?, true} <- {:question_found?, is_map(question)},
           {:is_open?, true} <- is_open?(question.assessment),
           {:ok, submission} <- find_or_create_submission(user, question.assessment),
           {:status, true} <- {:status, submission.status != :submitted},
           {:ok, answer} <- insert_or_update_answer(submission, question, raw_answer) do
        update_submission_status(submission, question.assessment)

        if answer.room_id == nil do
          Room.create_rooms(submission, answer, user)
        end

        {:ok, nil}
      else
        {:question_found?, false} -> {:error, {:not_found, "Question not found"}}
        {:is_open?, false} -> {:error, {:forbidden, "Assessment not open"}}
        {:status, _} -> {:error, {:forbidden, "Assessment submission already finalised"}}
        {:error, :race_condition} -> {:error, {:internal_server_error, "Please try again later."}}
        _ -> {:error, {:bad_request, "Missing or invalid parameter(s)"}}
      end
    else
      {:error, {:forbidden, "User is not permitted to answer questions"}}
    end
  end

  def finalise_submission(assessment_id, %User{role: role, id: user_id})
      when is_ecto_id(assessment_id) do
    if role in @submit_answer_roles do
      submission =
        Submission
        |> where(assessment_id: ^assessment_id)
        |> where(student_id: ^user_id)
        |> join(:inner, [s], a in assoc(s, :assessment))
        |> preload([_, a], assessment: a)
        |> Repo.one()

      with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
           {:is_open?, true} <- is_open?(submission.assessment),
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
    else
      {:error, {:forbidden, "User is not permitted to answer questions"}}
    end
  end

  def unsubmit_submission(submission_id, user = %User{id: user_id, role: role})
      when is_ecto_id(submission_id) do
    if role in @unsubmit_assessment_role do
      submission =
        Submission
        |> join(:inner, [s], a in assoc(s, :assessment))
        |> preload([_, a], assessment: a)
        |> Repo.get(submission_id)

      with {:submission_found?, true} <- {:submission_found?, is_map(submission)},
           {:is_open?, true} <- is_open?(submission.assessment),
           {:status, :submitted} <- {:status, submission.status},
           {:allowed_to_unsubmit?, true} <-
             {:allowed_to_unsubmit?,
              role == :admin || Cadet.Accounts.Query.avenger_of?(user, submission.student_id)} do
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
                   autograding_results: [],
                   grader_id: nil,
                   comments: nil
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
  Function returning submissions under a grader.

  The input parameters are the user and group_only.
  group_only is used to check whether only the groups under the grader should be returned.
  The parameter is a boolean which is false by default.

  The return value is {:ok, submissions} if no errors else its
  {:error, {:unauthorized, "User is not permitted to grade."}}
  """
  @spec all_submissions_by_grader(%User{}) ::
          {:ok, [%Submission{}]} | {:error, {:unauthorized, String.t()}}
  def all_submissions_by_grader(grader = %User{role: role}, group_only \\ false) do
    submission_query =
      Submission
      |> join(
        :inner,
        [s],
        x in subquery(Query.submissions_xp_and_grade()),
        on: s.id == x.submission_id
      )
      |> join(:inner, [s, _], st in assoc(s, :student))
      |> join(:left, [_, _, st], g in assoc(st, :group))
      |> join(:left, [s, _, _, g], u in assoc(s, :unsubmitted_by))
      |> join(
        :inner,
        [s, _, _, _, _],
        a in subquery(Query.all_assessments_with_max_xp_and_grade()),
        on: s.assessment_id == a.id
      )
      |> join(
        :inner,
        [_, _, _, _, _, a],
        q_count in subquery(Query.assessments_question_count()),
        on: a.id == q_count.assessment_id
      )
      |> join(
        :left,
        [s, _, _, _, _, a, _],
        g_count in subquery(Query.submissions_graded_count()),
        on: s.id == g_count.submission_id
      )
      |> select([s, x, st, g, u, a, q_count, g_count], %Submission{
        s
        | grade: x.grade,
          adjustment: x.adjustment,
          xp: x.xp,
          xp_adjustment: x.xp_adjustment,
          student: st,
          assessment: a,
          group_name: g.name,
          unsubmitted_by: u,
          question_count: q_count.count,
          graded_count: g_count.count
      })

    cond do
      role in @grading_roles ->
        submissions = submissions_by_group(grader, submission_query)

        {:ok, build_submission_grading_status(submissions)}

      role in @see_all_submissions_roles ->
        submissions =
          if group_only do
            submissions_by_group(grader, submission_query)
          else
            Repo.all(submission_query)
          end

        {:ok, build_submission_grading_status(submissions)}

      true ->
        {:error, {:unauthorized, "User is not permitted to grade."}}
    end
  end

  # Constructs grading status for each submission
  defp build_submission_grading_status(submissions) do
    submissions
    |> Enum.map(fn s = %Submission{} ->
      %{
        s
        | grading_status:
            build_grading_status(s.status, s.assessment.type, s.question_count, s.graded_count)
      }
    end)
  end

  @spec get_answers_in_submission(integer() | String.t(), %User{}) ::
          {:ok, [%Answer{}]} | {:error, {:unauthorized, String.t()}}
  def get_answers_in_submission(id, grader = %User{role: role}) when is_ecto_id(id) do
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

    cond do
      role in @grading_roles ->
        students = Cadet.Accounts.Query.students_of(grader)

        answers =
          answer_query
          |> join(:inner, [..., s, _], t in subquery(students), on: t.id == s.student_id)
          |> Repo.all()
          |> Enum.sort_by(& &1.question.display_order)

        {:ok, answers}

      role in @see_all_submissions_roles ->
        answers =
          answer_query
          |> Repo.all()
          |> Enum.sort_by(& &1.question.display_order)

        {:ok, answers}

      true ->
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
        grader = %User{id: grader_id, role: role}
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) and
             (role in @grading_roles or role in @see_all_submissions_roles) do
    attrs = Map.put(attrs, "grader_id", grader_id)

    answer_query =
      Answer
      |> where(submission_id: ^submission_id)
      |> where(question_id: ^question_id)

    # checks if role is in @grading_roles or @see_all_submissions_roles
    answer_query =
      if role in @grading_roles do
        students = Cadet.Accounts.Query.students_of(grader)

        answer_query
        |> join(:inner, [a], s in assoc(a, :submission))
        |> join(:inner, [a, s], t in subquery(students), on: t.id == s.student_id)
      else
        answer_query
        |> join(:inner, [a], s in assoc(a, :submission))
        |> preload([_, s], submission: s)
      end

    answer = Repo.one(answer_query)

    with {:answer_found?, true} <- {:answer_found?, is_map(answer)},
         {:status, :submitted} <- {:status, answer.submission.status},
         {:valid, changeset = %Ecto.Changeset{valid?: true}} <-
           {:valid, Answer.grading_changeset(answer, attrs)},
         {:ok, _} <- Repo.update(changeset) do
      if is_fully_graded?(answer) do
        # Every answer in this submission has been graded manually
        Notifications.write_notification_when_graded(submission_id, :graded)
      else
        {:ok, nil}
      end
    else
      {:answer_found?, false} ->
        {:error, {:bad_request, "Answer not found or user not permitted to grade."}}

      {:valid, changeset} ->
        {:error, {:bad_request, full_error_messages(changeset.errors)}}

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

  @doc """
  Checks if an assessment is open and published.
  """
  @spec is_open?(%Assessment{}) :: {:is_open?, boolean()}
  def is_open?(%Assessment{open_at: open_at, close_at: close_at, is_published: is_published}) do
    {:is_open?, Timex.between?(Timex.now(), open_at, close_at) and is_published}
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

  defp submissions_by_group(grader = %User{role: :staff}, submission_query) do
    students = Cadet.Accounts.Query.students_of(grader)

    submission_query
    |> join(:inner, [s], st in subquery(students), on: s.student_id == st.id)
    |> Repo.all()
  end

  defp submissions_by_group(%User{role: :admin}, submission_query) do
    Repo.all(submission_query)
  end
end
