defmodule Cadet.Assessments.QuestionTypes.MCQChoice do
  @moduledoc """
  The Assessments.QuestionTypes.MCQChoice entity represents an MCQ Choice.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Cadet.Assessments.QuestionTypes.MCQQuestion

  embedded_schema do
    field(:content, :string)
    field(:hint, :string)
    field(:is_correct, :boolean, default: false)
  end

  @required_fields ~w(content)a
  @optional_fields ~w(hint is_correct)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
