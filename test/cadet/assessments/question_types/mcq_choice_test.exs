defmodule Cadet.Assessments.QuestionTypes.MCQChoiceTest do
  alias Cadet.Assessments.QuestionTypes.MCQChoice

  use Cadet.ChangesetCase, entity: MCQChoice

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{choice_id: 1, content: "asd", is_correct: true}, :valid)
      assert_changeset(%{choice_id: 4, content: "asd", hint: "asd", is_correct: true}, :valid)
    end

    test "invalid changesets" do
      assert_changeset(%{choice_id: 1, content: "asd"}, :invalid)
      assert_changeset(%{choice_id: 1, hint: "asd"}, :invalid)
      assert_changeset(%{choice_id: 1, is_correct: false}, :invalid)
      assert_changeset(%{choice_id: 1, content: "asd", hint: "aaa"}, :invalid)
      assert_changeset(%{content: 1, is_correct: true}, :invalid)
      assert_changeset(%{choice_id: 6, content: 1, is_correct: true}, :invalid)
      assert_changeset(%{choice_id: -1, content: 1, is_correct: true}, :invalid)
    end
  end
end
