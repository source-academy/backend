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
    field(:reveal_hours, :integer)
    field(:token_divider, :integer)
    field(:xp_values, {:array, :integer}, default: [500, 400, 300])
  end

  @required_fields ~w(content contest_number reveal_hours token_divider)a
  @optional_fields ~w(prepend template xp_values)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:token_divider, greater_than: 0)
  end
end
