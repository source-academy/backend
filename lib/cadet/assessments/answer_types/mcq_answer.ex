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

  def changeset(answer, params \\ %{}) do
    answer
    |> cast_embed(:answer_choice, with: &MCQChoice.changeset/2, required: true)
  end
end
