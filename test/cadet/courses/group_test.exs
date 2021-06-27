defmodule Cadet.Courses.GroupTest do
  alias Cadet.Courses.Group

  use Cadet.ChangesetCase, entity: Group

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{name: "test", course_id: 1}, :valid)
      assert_changeset(%{name: "tst"}, :invalid)
    end
  end
end
