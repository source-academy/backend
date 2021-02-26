defmodule Cadet.Assessments.QuestionTypes.ContestEntry do
  @moduledoc """
  The Assessments.QuestionTypes.ContestEntry entity represents an Contest Entry.
  """
  use Cadet, :model

  @primary_key false
  embedded_schema do
    field(:submission_id, :integer)
    field(:answer, :string)
    field(:score, :integer)
  end

  @required_fields ~w(submission_id answer)a
  @optional_fields ~w(score)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:score, greater_than_or_equal_to: 0)
  end
end
