defmodule Cadet.Assessments.QuestionTypes.VotingQuestion do
  @moduledoc """
  The VotingQuestion entity represents a Voting question.
  """
  use Cadet, :model

  @primary_key false
  embedded_schema do
    field(:content, :string)
    field(:prepend, :string, default: "")
    field(:template, :string)
    field(:contest_number, :string)
  end

  @required_fields ~w(content contest_number)a
  @optional_fields ~w(prepend template)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
