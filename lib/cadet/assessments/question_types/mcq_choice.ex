defmodule Cadet.Assessments.QuestionTypes.MCQChoice do
  @moduledoc """
  The Assessments.QuestionTypes.MCQChoice entity represents an MCQ Choice.
  """
  use Ecto.Schema

  import Ecto.Changeset
  # TODO: use Cadet context after !34 is merged

  embedded_schema do
    field(:content, :string)
    field(:hint, :string)
    field(:is_correct, :boolean)
    field(:choice_id, :integer)
  end

  @required_fields ~w(content is_correct choice_id)a
  @optional_fields ~w(is_correct)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:choice_id, greater_than_or_equal_to: 0)
  end
end
