defmodule Cadet.Assessments.AnswerTypes.MCQAnswerTest do
  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  use Cadet.ChangesetCase, entity: MCQAnswer

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{choice_id: 0}, :valid)
      assert_changeset(%{choice_id: 1}, :valid)
      assert_changeset(%{choice_id: 2}, :valid)
      assert_changeset(%{choice_id: 3}, :valid)
      assert_changeset(%{choice_id: 4}, :valid)
    end

    test "invalid changesets" do
      assert_changeset(%{choice_id: -2}, :invalid)
    end
  end
end
