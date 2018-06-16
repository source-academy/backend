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
    field(:is_correct, :boolean)
    field(:choice_id, :integer)
  end

  @required_fields ~w(content is_correct choice_id)a
  @optional_fields ~w(is_correct)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
<<<<<<< Updated upstream
    |> validate_number(:choice_id, "greater_than": 0, "less_than": 5)
=======
    |> validate_number(:choice_id, greater_than: 0, less_than: 5)
>>>>>>> Stashed changes
  end
end
