defmodule Cadet.Assessments.Answer do
  @moduledoc """
  Answers model contains domain logic for answers management for
  programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.{Question, QuestionType, Submission}
  alias Cadet.Assessments.AnswerTypes.{MCQAnswer, ProgrammingAnswer}

  schema "answers" do
    field(:xp, :integer, default: 0)
    field(:answer, :map)
    field(:type, QuestionType, virtual: true)
    field(:comment, :string)
    field(:adjustment, :integer, default: 0)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)
    timestamps()
  end

  @required_fields ~w(answer submission_id question_id type)a
  @optional_fields ~w(xp comment adjustment)a

  def changeset(answer, params, allowed_fields \\ @required_fields ++ @optional_fields) do
    answer
    |> cast(params, allowed_fields)
    |> add_belongs_to_id_from_model([:submission, :question], params)
    |> add_question_type_from_model(params)
    |> validate_required(@required_fields)
    |> validate_number(:xp, greater_than_or_equal_to: 0.0)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
    |> validate_answer_content()
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
    with true <- changeset.valid?,
         question_type when is_atom(question_type) <- get_change(changeset, :type),
         answer when is_map(answer) <- get_change(changeset, :answer),
         false <- answer_structure_valid?(question_type, answer) do
      add_error(changeset, :answer, "invalid answer type provided for question")
    else
      _ -> changeset
    end
  end

  defp answer_structure_valid?(question_type, answer) do
    question_type
    |> case do
      :programming ->
        ProgrammingAnswer.changeset(%ProgrammingAnswer{}, answer)

      :multiple_choice ->
        MCQAnswer.changeset(%MCQAnswer{}, answer)
    end
    |> Map.get(:valid?)
  end
end
