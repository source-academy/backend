defmodule Cadet.Assessments.Answer do
  @moduledoc """
  Answers model contains domain logic for answers management for
  programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.AnswerTypes.{MCQAnswer, ProgrammingAnswer}
  alias Cadet.Assessments.{Question, QuestionType, Submission}

  schema "answers" do
    field(:grade, :integer, default: 0)
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

  @spec validate_grade_adjustment_total(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_grade_adjustment_total(changeset) do
    answer = apply_changes(changeset)

    if answer.grade + answer.adjustment >= 0 do
      changeset
    else
      add_error(changeset, :adjustment, "should not make total point < 0")
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
