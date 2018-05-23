defmodule Cadet.Assessments.QuestionTypes.MCQQuestion do
  @moduledoc """
  The Assessments.QuestionTypes.MCQQuestion entity represents an MCQ Question.
  It comprises of content and choices.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Cadet.Assessments.QuestionTypes.MCQChoice

  embedded_schema do
    field(:content, :string)
    embeds_many(:choices, MCQChoice)
    field(:raw_mcqquestion, :string, virtual: true)
  end

  @required_fields ~w(content)a
  @optional_fields ~w(raw_mcqquestion)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> put_question()
    |> cast_embed(:choices, with: &MCQChoice.changeset/2, required: true)
    |> validate_one_correct_answer()
    |> validate_required(@required_fields ++ ~w(choices)a)
  end

  defp put_question(changeset) do
    change = get_change(changeset, :raw_mcqquestion)

    if change do
      json = Poison.decode!(change)

      IO.puts(inspect(json))

      changeset
      |> cast(json, @required_fields)
    else
      changeset
    end
  end

  defp validate_one_correct_answer(changeset) do
    changeset
    |> validate_change(:choices, fn :choices, choices ->
      no_of_correct_choices =
        choices
        |> Enum.reduce(0, &if(&1.changes && &1.changes[:is_correct], do: &2 + 1, else: &2))

      if no_of_correct_choices == 1 do
        []
      else
        [choices: "Number of correct answer must be one."]
      end
    end)
  end
end
