defmodule Cadet.Assessments.AnswerTypes.MCQAnswerTest do
  use Cadet.ChangesetCase, async: true
  
  import Ecto.Changeset
  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  test "valid changeset with correct choice" do
    changeset = change(%MCQAnswer{})
    changeset = change(changeset, %{answer_choice: 
      %{content: "asd", is_correct: true}})
    changeset = MCQAnswer.changeset(changeset)
    assert changeset.valid?
  end
  
  test "valid changeset with wrong choice" do
    changeset = change(%MCQAnswer{})
    changeset = change(changeset, %{answer_choice: 
      %{content: "asd", is_correct: false}})
    changeset = MCQAnswer.changeset(changeset)
    assert changeset.valid?
  end

  test "invalid changeset with invalid" do
    changeset = change(%MCQAnswer{})
    changeset = MCQAnswer.changeset(changeset)
    refute changeset.valid?
  end
end
