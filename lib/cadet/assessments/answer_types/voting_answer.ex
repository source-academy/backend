defmodule Cadet.Assessments.AnswerTypes.VotingAnswer do
  @moduledoc """
  The VotingQuestion entity represents a Voting question.
  """
  use Cadet, :model

  @primary_key false
  embedded_schema do
    field(:completed, :boolean)
  end

  @required_fields ~w(completed)a

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
