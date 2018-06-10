defmodule Cadet.Assessments.AnswerTypes.MCQAnswer do
  @moduledoc """
  The Assessments.QuestionTypes.MCQQuestion entity represents an MCQ Question.
  It comprises of content and choices.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Cadet.Assessments.QuestionTypes.MCQChoice

  embedded_schema do
    field(:answer_choice, MCQChoice)
  end

  @required_fields ~w(answer_choice)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

end
