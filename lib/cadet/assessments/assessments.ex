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
  alias Cadet.Assessments.Query
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.Submission

  @grading_roles ~w(staff)a

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

  @spec get_submission_xp(String.t() | integer()) :: number()
  def get_submission_xp(id) when is_binary(id) or is_integer(id) do
    Answer
    |> where(submission_id: ^id)
    |> Repo.aggregate(:sum, :marks)
  end

  # def all_submissions_by_grader(grader, preload \\ true)

  # @spec all_submissions_by_grader(String.t() | integer(), boolean()) :: Submission.t()
  # def all_submissions_by_grader(grader_id, preload)
  #     when is_binary(grader_id) or is_integer(grader_id) do
  #   submissions =
  #     Submission
  #     |> where(grader_id: ^grader_id)
  #     |> Repo.all()

  #   if preload do
  #     submissions
  #     |> Repo.preload([:assessment, :student])
  #     |> Enum.map(&Map.put(&1, :xp, get_submission_xp(&1.id)))
  #   else
  #     submissions
  #   end
  # end

  @spec all_submissions_by_grader(User.t()) :: Submission.t()
  def all_submissions_by_grader(%User{id: id, role: role}) do
    if role in @grading_roles do
      submissions =
        Submission
        |> join(:left, [s], a in subquery(Query.submissions_xp()), a.submission_id == s.id)
        |> select([s, a], %{s | xp: a.xp})
        |> where(grader_id: ^id)
        |> preload([:assessment, :student])
        |> Repo.all()

      {:ok, submissions}
    else
      {:error, {:unauthorized, "User is not permitted to grade submissions"}}
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
