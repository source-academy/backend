defmodule Cadet.Assessments.AnswerTypes.VotingAnswer do
  @moduledoc """
  The Assessments.QuestionTypes.VotingQuestion entity represents an Voting Answer.
  It comprises of the ranks of the contest entries.
  """
  use Cadet, :model

  @primary_key false
  embedded_schema do
    field(:rankings, {:array, :integer})
  end

  @required_fields ~w(rankings)a

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_subset(:rankings, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  end
end
