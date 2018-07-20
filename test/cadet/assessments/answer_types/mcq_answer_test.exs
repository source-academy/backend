defmodule Cadet.Assessments.AnswerTypes.MCQAnswerTest do
  alias Cadet.Assessments.AnswerTypes.MCQAnswer

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: MCQAnswer

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{choice_id: 0})
      assert_changeset(%{choice_id: 1})
      assert_changeset(%{choice_id: 2})
      assert_changeset(%{choice_id: 3})
      assert_changeset(%{choice_id: 4})
    end

    test "invalid changesets" do
      assert_changeset(%{choice_id: -2}, :invalid)
    end
  end
end
