defmodule Cadet.Assessments.AnswerTypes.MCQAnswer do
  @moduledoc """
  The Assessments.QuestionTypes.MCQQuestion entity represents an MCQ Answer.
  It comprises of one of the MCQ choices.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Cadet.Assessments.QuestionTypes.MCQChoice

  embedded_schema do
<<<<<<< Updated upstream
    field(:choice_id, :integer)  
=======
    field(:choice_id, :integer)
>>>>>>> Stashed changes
  end

  @required_fields ~w(choice_id)a

  def changeset(answer, params \\ %{}) do
    answer
    |> cast(params, @required_fields)
    |> validate_number(:choice_id, greater_than: 0, less_than: 5)
  end
end
