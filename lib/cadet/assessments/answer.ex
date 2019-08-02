defmodule Cadet.Assessments.Answer do
  @moduledoc """
  Answers model contains domain logic for answers management for
  programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Repo
  alias Cadet.Accounts.User
  alias Cadet.Assessments.Answer.AutogradingStatus
  alias Cadet.Assessments.AnswerTypes.{MCQAnswer, ProgrammingAnswer}
  alias Cadet.Assessments.{Question, QuestionType, Submission}

  schema "answers" do
    field(:grade, :integer, default: 0)
    field(:adjustment, :integer, default: 0)
    field(:xp, :integer, default: 0)
    field(:xp_adjustment, :integer, default: 0)
    field(:autograding_status, AutogradingStatus, default: :none)
    field(:autograding_results, {:array, :map}, default: [])
    field(:answer, :map)
    field(:type, QuestionType, virtual: true)
    field(:room_id, :string)

    belongs_to(:grader, User)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)

    timestamps()
  end

  @required_fields ~w(answer submission_id question_id type)a
  @optional_fields ~w(xp xp_adjustment grade adjustment grader_id)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model([:submission, :question], params)
    |> add_question_type_from_model(params)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
    |> validate_answer_content()
    |> validate_xp_grade_adjustment_total()
  end

  @spec grading_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def grading_changeset(answer, params) do
    answer
    |> cast(
      params,
      ~w(grader_id xp xp_adjustment grade adjustment autograding_results autograding_status)a
    )
    |> add_belongs_to_id_from_model(:grader, params)
    |> foreign_key_constraint(:grader_id)
    |> validate_xp_grade_adjustment_total()
  end

  @spec autograding_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def autograding_changeset(answer, params) do
    answer
    |> cast(params, ~w(grade adjustment xp autograding_status autograding_results)a)
    |> validate_xp_grade_adjustment_total()
  end

  # TODO: add some validation
  @spec room_id_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def room_id_changeset(answer, params) do
    cast(answer, params, ~w(room_id)a)
  end

  @spec validate_xp_grade_adjustment_total(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_xp_grade_adjustment_total(changeset) do
    answer = apply_changes(changeset)

    total_grade = answer.grade + answer.adjustment

    total_xp = answer.xp + answer.xp_adjustment

    with {:question_id, question_id} when is_ecto_id(question_id) <-
           {:question_id, answer.question_id},
         {:question, %{max_grade: max_grade, max_xp: max_xp}} <-
           {:question, Repo.get(Question, question_id)},
         {:total_grade, true} <- {:total_grade, total_grade >= 0 and total_grade <= max_grade},
         {:total_xp, true} <- {:total_xp, total_xp >= 0 and total_xp <= max_xp} do
      changeset
    else
      {:question_id, _} ->
        add_error(changeset, :question_id, "is required")

      {:question, _} ->
        add_error(changeset, :question_id, "refers to non-existent question")

      {:total_grade, false} ->
        add_error(changeset, :adjustment, "must make total be between 0 and question.max_grade")

      {:total_xp, false} ->
        add_error(changeset, :xp_adjustment, "must make total be between 0 and question.max_xp")
    end
    |> validate_number(:grade, greater_than_or_equal_to: 0)
    |> validate_number(:xp, greater_than_or_equal_to: 0)
  end

  defp add_question_type_from_model(changeset, params) do
    with question when is_map(question) <- Map.get(params, :question),
         nil <- get_change(changeset, :type),
         type when is_atom(type) <- Map.get(question, :type) do
      change(changeset, %{type: type})
    else
      _ -> changeset
    end
  end

  defp validate_answer_content(changeset) do
    validate_arbitrary_embedded_struct_by_type(changeset, :answer, %{
      mcq: MCQAnswer,
      programming: ProgrammingAnswer
    })
  end
end
