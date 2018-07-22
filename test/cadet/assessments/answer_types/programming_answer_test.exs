defmodule Cadet.Assessments.AnswerTypes.ProgrammingAnswerTest do
  alias Cadet.Assessments.AnswerTypes.ProgrammingAnswer

  use Cadet.ChangesetCase, entity: ProgrammingAnswer

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{code: "This is some code"}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{}, :invalid)
    end
  end
end
