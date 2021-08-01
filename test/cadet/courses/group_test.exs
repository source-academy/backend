defmodule Cadet.Courses.GroupTest do
  alias Cadet.Courses.Group

  use Cadet.ChangesetCase, entity: Group

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{name: "test", course_id: 1}, :valid)
      assert_changeset(%{name: "tst"}, :invalid)
    end

    test "validate role" do
      course = insert(:course)
      student = insert(:course_registration, %{course: course, role: :student})
      staff = insert(:course_registration, %{course: course, role: :staff})
      admin = insert(:course_registration, %{course: course, role: :admin})

      assert_changeset(%{name: "test", course_id: course.id, leader_id: staff.id}, :valid)
      assert_changeset(%{name: "test", course_id: course.id, leader_id: admin.id}, :valid)
      assert_changeset(%{name: "test", course_id: course.id, leader_id: student.id}, :invalid)
    end

    test "validate course" do
      course = insert(:course)
      student = insert(:course_registration, %{course: course, role: :student})
      staff = insert(:course_registration, %{course: course, role: :staff})
      admin = insert(:course_registration, %{course: course, role: :admin})

      assert_changeset(%{name: "test", course_id: course.id + 1, leader_id: staff.id}, :invalid)
      assert_changeset(%{name: "test", course_id: course.id + 1, leader_id: admin.id}, :invalid)
      assert_changeset(%{name: "test", course_id: course.id + 1, leader_id: student.id}, :invalid)
    end
  end
end
