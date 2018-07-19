defmodule Cadet.Assessments.Question do
  @moduledoc """
  Questions model contains domain logic for questions management
  including programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.{Assessment, Library, QuestionType}
  alias Cadet.Assessments.QuestionTypes.{MCQQuestion, ProgrammingQuestion}

  schema "questions" do
    field(:title, :string)
    field(:display_order, :integer)
    field(:question, :map)
    field(:type, QuestionType)
    field(:max_xp, :integer)
    field(:answer, :map, virtual: true)
    embeds_one(:library, Library)
    belongs_to(:assessment, Assessment)
    timestamps()
  end

  @required_fields ~w(title question type assessment_id)a
  @optional_fields ~w(display_order max_xp)a
  @required_embeds ~w(library)a

  def changeset(question, params) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:library)
    |> validate_required(@required_fields ++ @required_embeds)
    |> validate_question_content()
    |> foreign_key_constraint(:assessment)
  end

  defp validate_question_content(changeset) do
    with true <- changeset.valid?,
         question_type when is_atom(question_type) <- get_change(changeset, :type),
         question when is_map(question) <- get_change(changeset, :question),
         false <- question_structure_valid?(question_type, question) do
      add_error(changeset, :answer, "invalid question provided for question type")
    else
      _ -> changeset
    end
  end

  defp question_structure_valid?(question_type, question) do
    question_type
    |> case do
      :programming ->
        ProgrammingQuestion.changeset(%ProgrammingQuestion{}, question)

      :mcq ->
        MCQQuestion.changeset(%MCQQuestion{}, question)
    end
    |> Map.get(:valid?)
  end
end
