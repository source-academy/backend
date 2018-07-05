defmodule Cadet.Assessments do
  @moduledoc """
  Assessments context contains domain logic for assessments management such as
  missions, sidequests, paths, etc.
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Timex.Duration

  alias Cadet.Accounts.User
  alias Cadet.Assessments.Answer
  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.Submission

  @submit_answer_roles ~w(student staff)a

  def all_assessments() do
    Repo.all(Assessment)
  end

  def all_assessments(category) do
    Repo.all(from(a in Assessment, where: a.category == ^category))
  end

  def all_open_assessments(category) do
    now = Timex.now()

    assessment_with_category = Repo.all(from(a in Assessment, where: a.category == ^category))
    # TODO: Refactor to be done on SQL instead of in-memory
    Enum.filter(assessment_with_category, &(&1.is_published and Timex.before?(&1.open_at, now)))
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
        |> build_question
        |> put_assoc(:assessment, assessment)
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

  def answer_question(id, user, raw_answer) do
    if user.role not in @submit_answer_roles do
      {:error, {:unauthorized, "User is not permitted to answer questions"}}
    else
      question =
        Question
        |> where([q], q.id == ^id)
        |> join(:inner, [q], assessment in assoc(q, :assessment))
        |> preload([question, assessment], assessment: assessment)
        |> Repo.one()

      cond do
        is_nil(question) ->
          {:error, {:bad_request, "Question not found"}}

        Question.is_overdue?(question) ->
          {:error, {:bad_request, "Assessment closed"}}

        true ->
          submission = find_or_create_submission(user, question.assessment)
          insert_or_update_answer(submission, question, raw_answer)
      end
    end
  end

  defp find_submission(user = %User{}, assessment = %Assessment{}) do
    submission =
      Submission
      |> where([s], s.student_id == ^user.id)
      |> where([s], s.assessment_id == ^assessment.id)
      |> Repo.one()

    if submission do
      {:ok, submission}
    else
      {:error, nil}
    end
  end

  defp create_empty_submission(user = %User{}, assessment = %Assessment{}) do
    %Submission{}
    |> Submission.changeset(%{student: user, assessment: assessment})
    |> Repo.insert!()
  end

  defp find_or_create_submission(user = %User{}, assessment = %Assessment{}) do
    case find_submission(user, assessment) do
      {:ok, submission} -> submission
      {:error, _} -> create_empty_submission(user, assessment)
    end
  end

  defp insert_or_update_answer(submission = %Submission{}, question = %Question{}, raw_answer) do
    answer_content = build_answer_content(raw_answer, question.type)

    %Answer{}
    |> Answer.changeset(%{
      answer: answer_content,
      question_id: question.id,
      submission_id: submission.id
    })
    |> Repo.insert(
      on_conflict: [set: [answer: answer_content]],
      conflict_target: [:submission_id, :question_id]
    )
    |> case do
      {:ok, _answer} ->
        {:ok, nil}

      {:error, _error} ->
        {:error, {:bad_request, "Missing or invalid parameter(s)"}}
    end
  end

  defp build_answer_content(raw_answer, question_type) do
    case question_type do
      :multiple_choice ->
        %{choice_id: raw_answer}

      :programming ->
        %{code: raw_answer}
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
