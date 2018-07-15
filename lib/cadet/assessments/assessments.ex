defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Timex.Duration

  alias Cadet.Accounts.User
  alias Cadet.Assessments.{Answer, Assessment, Query, Question, Submission}

  @submit_answer_roles ~w(student)a
  @grading_roles ~w(staff)a

  def all_assessments(assessment_type) do
    Assessment
    |> where(type: ^assessment_type)
    |> Repo.all()
  end

  def all_open_assessments(assessment_type) do
    Assessment
    |> where(is_published: true)
    |> where(type: ^assessment_type)
    |> where([a], a.open_at <= from_now(1, "second"))
    |> Repo.all()
  end

  def assessments_due_soon() do
    Assessment
    |> where(is_published: true)
    |> where([a], a.open_at <= from_now(1, "second"))
    |> where([a], a.close_at >= from_now(1, "second"))
    |> where([a], a.close_at <= from_now(1, "week"))
    |> Repo.all()
  end

  def create_assessment(params) do
    %Assessment{}
    |> Assessment.changeset(params)
    |> Repo.insert()
  end

  def update_assessment(id, params) do
    simple_update(
      Assessment,
      id,
      using: &Assessment.changeset/2,
      params: params
    )
  end

  def update_question(id, params) do
    simple_update(
      Question,
      id,
      using: &Question.changeset/2,
      params: params
    )
  end

  def publish_assessment(id) do
    simple_update(
      Assessment,
      id,
      using: &Assessment.changeset/2,
      params: %{is_published: true}
    )
  end

  def create_question_for_assessment(params, assessment_id) when is_ecto_id(assessment_id) do
    Repo.transaction(fn ->
      assessment =
        Assessment
        |> where(id: ^assessment_id)
        |> join(:left, [a], q in Question, q.assessment_id == a.id)
        |> preload([a, q], questions: q)
        |> Repo.one()

      params_with_assessment_id = Map.put_new(params, :assessment_id, assessment.id)

      changeset =
        %Question{}
        |> Question.changeset(params_with_assessment_id)
        |> put_display_order(assessment.questions)

      case Repo.insert(changeset) do
        {:ok, question} -> question
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def delete_question(id) do
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
  def answer_question(id, user = %User{role: role}, raw_answer) do
    if role in @submit_answer_roles do
      question =
        Question
        |> where(id: ^id)
        |> join(:inner, [q], assessment in assoc(q, :assessment))
        |> preload([q, a], assessment: a)
        |> Repo.one()

      with {:question_found?, true} <- {:question_found?, is_map(question)},
           {:is_open?, true} <- is_open?(question.assessment),
           {:ok, submission} <- find_or_create_submission(user, question.assessment),
           {:ok, _} <- insert_or_update_answer(submission, question, raw_answer) do
        {:ok, nil}
      else
        {:question_found?, false} -> {:error, {:bad_request, "Question not found"}}
        {:is_open?, false} -> {:error, {:forbidden, "Assessment not open"}}
        {:error, :race_condition} -> {:error, {:internal_server_error, "Please try again later."}}
        _ -> {:error, {:bad_request, "Missing or invalid parameter(s)"}}
      end
    else
      {:error, {:forbidden, "User is not permitted to answer questions"}}
    end
  end

  @spec all_submissions_by_grader(User.t()) ::
          {:ok, [Submission.t()]} | {:error, {:unauthorized, String.t()}}
  def all_submissions_by_grader(grader = %User{role: role}) do
    if role in @grading_roles do
      students = Cadet.Accounts.Query.students_of(grader)

      submissions =
        Submission
        |> join(:inner, [s], x in subquery(Query.submissions_xp()), s.id == x.submission_id)
        |> join(:inner, [s], st in subquery(students), s.student_id == st.id)
        |> join(
          :inner,
          [s],
          a in subquery(Query.all_assessments_with_max_xp()),
          s.assessment_id == a.id
        )
        |> select([s, x, st, a], %Submission{s | xp: x.xp, student: st, assessment: a})
        |> Repo.all()

      {:ok, submissions}
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
    end
  end

  @spec get_answers_in_submission(integer() | String.t(), User.t()) ::
          {:ok, [Answer.t()]} | {:error, {:unauthorized, String.t()}}
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
          User.t()
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

    %Answer{}
    |> Answer.changeset(%{
      answer: answer_content,
      question_id: question.id,
      submission_id: submission.id,
      type: question.type
    })
    |> Repo.insert(
      on_conflict: [set: [answer: answer_content]],
      conflict_target: [:submission_id, :question_id]
    )
  end

  defp build_answer_content(raw_answer, question_type) do
    case question_type do
      :multiple_choice ->
        %{choice_id: raw_answer}

      :programming ->
        %{code: raw_answer}
    end
  end
end
