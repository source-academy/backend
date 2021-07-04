defmodule Cadet.Courses.GroupTest do
  alias Cadet.Courses.Group

  use Cadet.ChangesetCase, entity: Group

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{name: "test", course_id: 1}, :valid)
      assert_changeset(%{name: "tst"}, :invalid)
    end

    test "validate role" do
      student = insert(:course_registration, %{role: :student})
      staff = insert(:course_registration, %{role: :staff})
      admin = insert(:course_registration, %{role: :admin})

      assert_changeset(%{name: "test", course_id: 1, leader_id: staff.id}, :valid)
      assert_changeset(%{name: "test", course_id: 1, leader_id: admin.id}, :valid)
      assert_changeset(%{name: "test", course_id: 1, leader_id: student.id}, :invalid)
    end
  end
end
