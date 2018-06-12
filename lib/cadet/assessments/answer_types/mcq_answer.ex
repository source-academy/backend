defmodule Cadet.Assessments.AnswerTypes.MCQAnswer do
  @moduledoc """
  The Assessments.QuestionTypes.MCQQuestion entity represents an MCQ Answer.
  It comprises of one of the MCQ choices.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Cadet.Assessments.QuestionTypes.MCQChoice

  embedded_schema do
    embeds_one(:answer_choice, MCQChoice)
  end

<<<<<<< HEAD
  @required_fields ~w(answer_choice)a

  def changeset(question, params \\ %{}) do
    question
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
=======
  def changeset(answer, params \\ %{}) do
    answer
    |> cast_embed(:answer_choice, with: &MCQChoice.changeset/2, required: true)
>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
  end
end
