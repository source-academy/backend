defmodule Cadet.Assessments.Question do
  @moduledoc """
  Questions model contains domain logic for questions management
  including programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.{Assessment, Library, QuestionType}
  alias Cadet.Assessments.QuestionTypes.{MCQQuestion, ProgrammingQuestion, VotingQuestion}

  @type t :: %__MODULE__{}

  schema "questions" do
    field(:display_order, :integer)
    field(:question, :map)
    field(:type, QuestionType)
    field(:max_xp, :integer)
    field(:show_solution, :boolean, default: false)
    field(:blocking, :boolean, default: false)
    field(:answer, :map, virtual: true)
    embeds_one(:library, Library, on_replace: :update)
    embeds_one(:grading_library, Library, on_replace: :update)
    belongs_to(:assessment, Assessment)
    timestamps()
  end

  @required_fields ~w(question type assessment_id)a
  @optional_fields ~w(display_order max_xp show_solution blocking)a
  @required_embeds ~w(library)a

  def changeset(question, params) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model(:assessment, params)
    |> cast_embed(:library)
    |> cast_embed(:grading_library)
    |> validate_required(@required_fields ++ @required_embeds)
    |> validate_question_content()
    |> foreign_key_constraint(:assessment_id)
  end

  defp validate_question_content(changeset) do
    validate_arbitrary_embedded_struct_by_type(changeset, :question, %{
      mcq: MCQQuestion,
      programming: ProgrammingQuestion,
      voting: VotingQuestion
    })
  end
end
