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

  def all_assessments() do
    Repo.all(Assessment)
  end

  def all_assessments(assessment_type) do
    Repo.all(from(a in Assessment, where: a.type == ^assessment_type))
  end

  def all_open_assessments(assessment_type) do
    now = Timex.now()

    assessment_with_type = Repo.all(from(a in Assessment, where: a.type == ^assessment_type))
    # TODO: Refactor to be done on SQL instead of in-memory
    Enum.filter(assessment_with_type, &(&1.is_published and Timex.before?(&1.open_at, now)))
  end

  def all_open_assessments() do
    assessments =
      Assessment
      |> where(is_published: true)
      |> Repo.all()

    {:ok, assessments}
  end

  def assessments_due_soon() do
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
      when is_binary(assessment_id) or is_number(assessment_id) do
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

  @spec all_submissions_by_grader(User.t()) ::
          {:ok, [Submission.t()]} | {:error, {:unauthorized, String.t()}}
  def all_submissions_by_grader(grader = %User{role: role}) do
    if role in @grading_roles do
      students = Cadet.Accounts.Query.students_of(grader)

      submissions =
        Query.all_submissions_with_xp()
        |> join(:inner, [s], t in subquery(students), s.student_id == t.id)
        |> preload([:student, assessment: ^Query.all_assessments_with_max_xp()])
        |> Repo.all()

      {:ok, submissions}
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
    end
  end

  def get_answers_in_submission(id, grader = %User{role: role}) do
    if role in @grading_roles do
      students = Cadet.Accounts.Query.students_of(grader)

      answers =
        Answer
        |> where(submission_id: ^id)
        |> join(:inner, [a], s in Submission, a.submission_id == s.id)
        |> join(:inner, [a, s], t in subquery(students), s.student_id == t.id)
        |> preload(:question)
        |> Repo.all()

      {:ok, answers}
    else
      {:error, {:unauthorized, "User is not permitted to grade."}}
    end
  end

  # TODO: Decide what to do with these methods
  # def create_multiple_choice_question(json_attr) when is_binary(json_attr) do
  #  %MCQQuestion{}
  #  |> MCQQuestion.changeset(%{raw_mcqquestion: json_attr})
  # end

  # def create_multiple_choice_question(attr = %{}) do
  #  %MCQQuestion{}
  #  |> MCQQuestion.changeset(attr)
  # end

  # def create_programming_question(json_attr) when is_binary(json_attr) do
  #  %ProgrammingQuestion{}
  #  |> ProgrammingQuestion.changeset(%{raw_programmingquestion: json_attr})
  # end

  # def create_programming_question(attr = %{}) do
  #  %ProgrammingQuestion{}
  #  |> ProgrammingQuestion.changeset(attr)
  # end
end
