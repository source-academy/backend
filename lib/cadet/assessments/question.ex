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
    field(:max_grade, :integer)
    field(:answer, :map, virtual: true)
    embeds_one(:library, Library)
    belongs_to(:assessment, Assessment)
    timestamps()
  end

  @required_fields ~w(title question type assessment_id)a
  @optional_fields ~w(display_order max_grade)a
  @required_embeds ~w(library)a

  def changeset(question, params) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:library)
    |> add_belongs_to_id_from_model(:assessment, params)
    |> validate_required(@required_fields ++ @required_embeds)
    |> validate_question_content()
    |> foreign_key_constraint(:assessment_id)
  end

  defp validate_question_content(changeset) do
    validate_arbitrary_embedded_struct_by_type(changeset, :question, %{
      mcq: MCQQuestion,
      programming: ProgrammingQuestion
    })
  end
end
