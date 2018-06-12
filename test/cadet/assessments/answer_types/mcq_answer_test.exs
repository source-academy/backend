defmodule Cadet.Assessments.AnswerTypes.MCQAnswerTest do
  use Cadet.ChangesetCase, async: true
<<<<<<< HEAD
  use Cadet.DataCase

  alias Cadet.Assessments.QuestionTypes.MCQChoice
  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  valid_changesets MCQAnswer do
    %{answer_choice: insert(:mcq_choice)}
  end

  invalid_changesets MCQAnswer do
    %{}
=======
  
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
>>>>>>> d08d50a55138354557a30d45d5423d8531f5c5b1
  end
end
