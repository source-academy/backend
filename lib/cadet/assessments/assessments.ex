defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Accounts.User
  alias Cadet.Assessments.{Answer, Assessment, Query, Question, Submission}
  alias Ecto.Multi

  @submit_answer_roles ~w(student)a
  @grading_roles ~w(staff)a

  def user_total_grade(%User{id: user_id}) do
    grade =
      Query.all_submissions_with_grade()
      |> subquery()
      |> where(student_id: ^user_id)
      |> select([q], fragment("? + ?", sum(q.grade), sum(q.adjustment)))
      |> Repo.one()

    if grade do
      Decimal.to_integer(grade)
    else
      0
    end
  end

  def user_current_story(user = %User{}) do
    {:ok, %{result: story}} =
      Multi.new()
      |> Multi.run(:unattempted, fn _ -> {:ok, get_user_story_by_type(user, :unattempted)} end)
      |> Multi.run(:result, fn %{unattempted: unattempted_story} ->
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
    |> join(:left, [a], s in Submission, s.assessment_id == a.id and s.student_id == ^user_id)
    |> filter_and_sort.()
    |> order_by([a], a.type)
    |> select([a], a.story)
    |> first()
    |> Repo.one()
  end

  def assessment_with_questions_and_answers(id, user = %User{}) when is_ecto_id(id) do
    assessment =
      Assessment
      |> where(id: ^id)
      |> where(is_published: true)
      |> Repo.one()

    if assessment do
      if Timex.after?(Timex.now(), assessment.open_at) do
        answer_query =
          Answer
          |> join(:inner, [a], s in assoc(a, :submission))
          |> where([_, s], s.student_id == ^user.id)

        questions =
          Question
          |> where(assessment_id: ^id)
          |> join(:left, [q], a in subquery(answer_query), q.id == a.question_id)
          |> select([q, a], %{q | answer: a})
          |> order_by(:display_order)
          |> Repo.all()

        assessment = Map.put(assessment, :questions, questions)
        {:ok, assessment}
      else
        {:error, {:unauthorized, "Assessment not open"}}
      end
    else
      {:error, {:bad_request, "Assessment not found"}}
    end
  end

  @doc """
  Returns a list of assessments with all fields and an indicator showing whether it has been attempted
  by the supplied user
  """
  def all_published_assessments(user = %User{}) do
    assessments =
      Query.all_assessments_with_max_grade()
      |> subquery()
      |> join(:left, [a], s in Submission, a.id == s.assessment_id and s.student_id == ^user.id)
      |> select([a, s], %{a | user_status: s.status})
      |> where(is_published: true)
      |> order_by(:open_at)
      |> Repo.all()

    {:ok, assessments}
  end

  def create_assessment(params) do
    %Assessment{}
    |> Assessment.changeset(params)
    |> Repo.insert()
  end

  def insert_or_update_assessment(params = %{number: number}) do
    Assessment
    |> where(number: ^number)
    |> Repo.one()
    |> case do
      nil -> %Assessment{}
      assessment -> assessment
    end
    |> Assessment.changeset(params)
    |> Repo.insert_or_update()
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
           {:ok, _} <- insert_or_update_answer(submission, question, raw_answer) do
        update_submission_status(submission, question.assessment)
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
           {:ok, _} <- submission |> Submission.changeset(%{status: :submitted}) |> Repo.update() do
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

  def update_submission_status(submission = %Submission{}, assessment = %Assessment{}) do
    model_assoc_count = fn model, assoc, id ->
      model
      |> where(id: ^id)
      |> join(:inner, [m], a in assoc(m, ^assoc))
      |> select([_, a], count(a.id))
      |> Repo.one()
    end

    Multi.new()
    |> Multi.run(:assessment, fn _ ->
      {:ok, model_assoc_count.(Assessment, :questions, assessment.id)}
    end)
    |> Multi.run(:submission, fn _ ->
      {:ok, model_assoc_count.(Submission, :answers, submission.id)}
    end)
    |> Multi.run(:update, fn %{submission: s_count, assessment: a_count} ->
      if s_count == a_count do
        submission |> Submission.changeset(%{status: :attempted}) |> Repo.update()
      else
        {:ok, nil}
      end
    end)
    |> Repo.transaction()
  end

  @spec all_submissions_by_grader(%User{}) ::
          {:ok, [%Submission{}]} | {:error, {:unauthorized, String.t()}}
  def all_submissions_by_grader(grader = %User{role: role}) do
    if role in @grading_roles do
      students = Cadet.Accounts.Query.students_of(grader)

      submissions =
        Submission
        |> join(:inner, [s], x in subquery(Query.submissions_grade()), s.id == x.submission_id)
        |> join(:inner, [s], st in subquery(students), s.student_id == st.id)
        |> join(
          :inner,
          [s],
          a in subquery(Query.all_assessments_with_max_grade()),
          s.assessment_id == a.id
        )
        |> select([s, x, st, a], %Submission{
          s
          | grade: x.grade,
            adjustment: x.adjustment,
            student: st,
            assessment: a
        })
        |> Repo.all()

      {:ok, submissions}
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
    end
  end

  @spec get_answers_in_submission(integer() | String.t(), %User{}) ::
          {:ok, [%Answer{}]} | {:error, {:unauthorized, String.t()}}
  def get_answers_in_submission(id, grader = %User{role: role}) when is_ecto_id(id) do
    if role in @grading_roles do
      students = Cadet.Accounts.Query.students_of(grader)

      answers =
        Answer
        |> where(submission_id: ^id)
        |> join(:inner, [a], s in Submission, a.submission_id == s.id)
        |> join(:inner, [a, s], t in subquery(students), t.id == s.student_id)
        |> join(:inner, [a], q in assoc(a, :question))
        |> preload([a, ..., q], question: q)
        |> Repo.all()

      {:ok, answers}
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
    end
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
        grader = %User{role: role}
      )
      when is_ecto_id(submission_id) and is_ecto_id(question_id) do
    if role in @grading_roles do
      students = Cadet.Accounts.Query.students_of(grader)

      answer =
        Answer
        |> where([a], a.submission_id == ^submission_id and a.question_id == ^question_id)
        |> join(:inner, [a], s in assoc(a, :submission))
        |> join(:inner, [a, s], t in subquery(students), t.id == s.student_id)
        |> Repo.one()

      with {:answer_found?, true} <- {:answer_found?, is_map(answer)},
           {:valid, changeset = %Ecto.Changeset{valid?: true}} <-
             {:valid, Answer.grading_changeset(answer, attrs)},
           {:ok, _} <- Repo.update(changeset) do
        {:ok, nil}
      else
        {:answer_found?, false} ->
          {:error, {:bad_request, "Answer not found or user not permitted to grade."}}

        {:valid, changeset} ->
          {:error, {:bad_request, full_error_messages(changeset.errors)}}

        {:error, _} ->
          {:error, {:internal_server_error, "Please try again later."}}
      end
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
    end
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

  defp is_open?(%Assessment{open_at: open_at, close_at: close_at, is_published: is_published}) do
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
end
