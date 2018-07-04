defmodule Cadet.Assessments.Question do
  @moduledoc """
  Questions model contains domain logic for questions management
  including programming and multiple choice questions.
  """
  use Cadet, [:model, :context]

  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.ProblemType
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion
  alias Cadet.Assessments.QuestionTypes.MCQQuestion

  schema "questions" do
    field(:title, :string)
    field(:display_order, :integer)
    field(:weight, :integer)
    field(:question, :map)
    field(:type, ProblemType)
    field(:raw_question, :string, virtual: true)
    belongs_to(:assessment, Assessment)
    timestamps()
  end

  @required_fields ~w(title weight question type)a
  @optional_fields ~w(display_order raw_question)a

  def changeset(question, params) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> put_question
  end

  def is_overdue?(question) do
    question =
      if Ecto.assoc_loaded?(question.assessment) do
        question
      else
        Ecto.preload(question, :assessment)
      end

    not Timex.between?(Timex.now(), question.assessment.open_at, question.assessment.close_at)
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
