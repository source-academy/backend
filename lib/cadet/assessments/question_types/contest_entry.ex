defmodule Cadet.Assessments.QuestionTypes.ContestEntry do
  @moduledoc """
  The Assessments.QuestionTypes.ContestEntry entity represents a Contest Entry.
  """
  use Cadet, :model

  @primary_key false
  embedded_schema do
    field(:submission_id, :integer)
    field(:answer, :string)
    field(:rank, :integer)
  end

  @required_fields ~w(submission_id answer)a
  @optional_fields ~w(rank)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:rank, greater_than_or_equal_to: 1)
  end
end
