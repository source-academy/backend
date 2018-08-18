defmodule Cadet.Assessments.Answer do
  @moduledoc """
  Answers model contains domain logic for answers management for
  programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Repo
  alias Cadet.Assessments.Answer.AutogradingStatus
  alias Cadet.Assessments.AnswerTypes.{MCQAnswer, ProgrammingAnswer}
  alias Cadet.Assessments.{Question, QuestionType, Submission}

  schema "answers" do
    field(:grade, :integer, default: 0)
    field(:xp, :integer, default: 0)
    field(:autograding_status, AutogradingStatus, default: :none)
    field(:autograding_errors, {:array, :map}, default: [])
    field(:answer, :map)
    field(:type, QuestionType, virtual: true)
    field(:comment, :string)
    field(:adjustment, :integer, default: 0)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)
    timestamps()
  end

  @required_fields ~w(answer submission_id question_id type)a
  @optional_fields ~w(grade comment adjustment)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model([:submission, :question], params)
    |> add_question_type_from_model(params)
    |> validate_required(@required_fields)
    |> validate_number(:grade, greater_than_or_equal_to: 0.0)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
    |> validate_answer_content()
  end

  @spec grading_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def grading_changeset(answer, params) do
    answer
    |> cast(params, ~w(adjustment comment)a)
    |> validate_grade_adjustment_total()
  end

  @spec autograding_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def autograding_changeset(answer, params) do
    cast(answer, params, ~w(grade adjustment autograding_status autograding_errors)a)
  end

  @spec validate_grade_adjustment_total(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_grade_adjustment_total(changeset) do
    answer = apply_changes(changeset)

    total = answer.grade + answer.adjustment

    with {:question_id, question_id} when is_ecto_id(question_id) <-
           {:question_id, answer.question_id},
         question <- Repo.get(Question, question_id),
         {:total, true} <- {:total, total >= 0 and total <= question.max_grade} do
      changeset
    else
      {:question_id, _} ->
        add_error(changeset, :question_id, "is required")

      {:total, false} ->
        add_error(changeset, :adjustment, "must make total be between 0 and question.max_grade")
    end
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
