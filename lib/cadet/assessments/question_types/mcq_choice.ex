defmodule Cadet.Assessments.QuestionTypes.MCQChoice do
  @moduledoc """
  The Assessments.QuestionTypes.MCQChoice entity represents an MCQ Choice.
  """
  use Cadet, :model

  embedded_schema do
    field(:content, :string)
    field(:hint, :string)
    field(:is_correct, :boolean)
  end

  @required_fields ~w(content is_correct)a
  @optional_fields ~w(hint)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
