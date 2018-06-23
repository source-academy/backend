defmodule Cadet.Assessments.AnswerTypes.MCQAnswer do
  @moduledoc """
  The Assessments.QuestionTypes.MCQQuestion entity represents an MCQ Answer.
  It comprises of one of the MCQ choices.
  """
  use Ecto.Schema

  import Ecto.Changeset
  # TODO: use Cadet context after !34 is merged

  embedded_schema do
    field(:choice_id, :integer)
  end

  @required_fields ~w(choice_id)a

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:choice_id, greater_than_or_equal_to: 0)
  end
end
