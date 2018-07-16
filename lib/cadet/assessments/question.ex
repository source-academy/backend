defmodule Cadet.Assessments.Question do
  @moduledoc """
  Questions model contains domain logic for questions management
  including programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.{Assessment, Library, QuestionType}

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

  def changeset(question, params) do
    # TODO: Implement foreign_key_validation
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:library)
    |> validate_required(@required_fields)
  end
end
