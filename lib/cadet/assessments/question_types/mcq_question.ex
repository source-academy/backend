defmodule Cadet.Assessments.QuestionTypes.MCQQuestion do
  @moduledoc """
  The Assessments.QuestionTypes.MCQQuestion entity represents an MCQ Question.
  It comprises of content and choices.
  """
  use Cadet, :model

  alias Cadet.Assessments.QuestionTypes.MCQChoice

  @primary_key false
  embedded_schema do
    field(:content, :string)
    embeds_many(:choices, MCQChoice)
  end

  @required_fields ~w(content)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields)
    |> cast_embed(:choices, with: &MCQChoice.changeset/2, required: true)
    |> validate_one_correct_answer
    |> validate_required(@required_fields ++ ~w(choices)a)
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
