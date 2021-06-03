defmodule Cadet.Courses.GroupTest do
  alias Cadet.Courses.Group

  use Cadet.ChangesetCase, entity: Group

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{}, :valid)
      assert_changeset(%{name: "tst"}, :valid)
    end
  end
end
