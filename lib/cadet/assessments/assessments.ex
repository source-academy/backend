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

  def all_assessments do
    Repo.all(Assessment)
  end

  def all_assessments(assessment_type) do
    Repo.all(from(a in Assessment, where: a.type == ^assessment_type))
  end

  def assessment_with_questions_and_answers(id, user = %User{}) when is_ecto_id(id) do
    assessment =
      Assessment
      |> where(id: ^id)
      |> where(is_published: true)
      |> select([:type, :title, :summary_long, :mission_pdf, :id, :open_at])
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

  def all_open_assessments(assessment_type) do
    now = Timex.now()

    assessment_with_type = Repo.all(from(a in Assessment, where: a.type == ^assessment_type))
    # TODO: Refactor to be done on SQL instead of in-memory
    Enum.filter(assessment_with_type, &(&1.is_published and Timex.before?(&1.open_at, now)))
  end

  @doc """
  Returns a list of assessments with all fields and an indicator showing whether it has been attempted
  by the supplied user
  """
  def all_published_assessments(user = %User{}) do
    assessments =
      Query.all_assessments_with_max_xp()
      |> subquery()
      |> join(:left, [a], s in Submission, a.id == s.assessment_id and s.student_id == ^user.id)
      |> select([a, s], %{a | attempted: not is_nil(s.id)})
      |> where(is_published: true)
      |> order_by(:open_at)
      |> Repo.all()

    {:ok, assessments}
  end

  def assessments_due_soon do
    now = Timex.now()
    week_after = Timex.add(now, Duration.from_weeks(1))

    all_assessments()
    |> Enum.filter(
      &(&1.is_published and Timex.before?(&1.open_at, now) and
          Timex.between?(&1.close_at, now, week_after))
    )
  end

  def build_assessment(params) do
    Assessment.changeset(%Assessment{}, params)
  end

  def build_question(params) do
    Question.changeset(%Question{}, params)
  end

  def create_assessment(params) do
    params
    |> build_assessment
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
    id
    |> get_assessment()
    |> change(%{is_published: true})
    |> Repo.update()
  end

  def get_question(id) do
    Repo.get(Question, id)
  end

  def get_assessment(id) do
    Repo.get(Assessment, id)
  end

  def create_question_for_assessment(params, assessment_id)
      when is_ecto_id(assessment_id) do
    assessment = get_assessment(assessment_id)
    create_question_for_assessment(params, assessment)
  end

  def create_question_for_assessment(params, assessment) do
    Repo.transaction(fn ->
      assessment = Repo.preload(assessment, :questions)
      questions = assessment.questions

      changeset =
        params
        |> Map.put_new(:assessment_id, assessment.id)
        |> build_question
        |> put_display_order(questions)

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
