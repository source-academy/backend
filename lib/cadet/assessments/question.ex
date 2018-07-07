defmodule Cadet.Assessments.Question do
  @moduledoc """
  Questions model contains domain logic for questions management
  including programming and multiple choice questions.
  """
  use Cadet, :model

  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.QuestionType
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion
  alias Cadet.Assessments.QuestionTypes.MCQQuestion
  alias Cadet.Assessments.Library

  schema "questions" do
    field(:title, :string)
    field(:display_order, :integer)
    field(:question, :map)
    field(:type, QuestionType)
    field(:raw_question, :string, virtual: true)
    field(:max_xp, :integer)
    embeds_one(:library, Library)
    belongs_to(:assessment, Assessment)
    timestamps()
  end

  @required_fields ~w(title question type assessment_id)a
  @optional_fields ~w(display_order raw_question max_xp)a

  def changeset(question, params) do
    # TODO: Implement foreign_key_validation
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:library)
    |> validate_required(@required_fields)
    |> put_question
  end

  defp put_question(changeset) do
    {:ok, json} =
      changeset
      |> get_change(:raw_question)
      |> Kernel.||("{}")
      |> Poison.decode()

    type = get_change(changeset, :type)

    case type do
      :programming ->
        put_change(
          changeset,
          :question,
          %ProgrammingQuestion{}
          |> ProgrammingQuestion.changeset(json)
          |> apply_changes
          |> Map.from_struct()
        )

      :multiple_choice ->
        put_change(
          changeset,
          :question,
          %MCQQuestion{}
          |> MCQQuestion.changeset(json)
          |> apply_changes
          |> Map.from_struct()
        )

      _ ->
        changeset
    end
  end
end
