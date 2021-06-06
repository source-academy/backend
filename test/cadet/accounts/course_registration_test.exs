defmodule Cadet.Accounts.CourseRegistrationTest do
  alias Cadet.Accounts.CourseRegistration

  use Cadet.ChangesetCase, entity: CourseRegistration

  alias Cadet.Repo

  setup do
    user1 = insert(:user, %{name: "test 1"})
    user2 = insert(:user, %{name: "test 2"})
    # group1 = insert(:group)
    course1 = insert(:course, %{module_code: "CS1101S"})
    course2 = insert(:course, %{module_code: "CS2040S"})

    {:ok, %{user1: user1, user2: user2, course1: course1, course2: course2}}
  end

  # :TODO add context function test
  describe "Changesets" do
    test "valid changeset", %{
      user1: user1,
      user2: user2,
      course1: course1,
      course2: course2
    } do
      assert_changeset(%{user_id: user1.id, course_id: course2.id, role: :admin}, :valid)
      assert_changeset(%{user_id: user2.id, course_id: course1.id, role: :student}, :valid)

      # assert_changeset(%{user_id: user2.id, course_id: course2.id, role: :staff, group_id: group.id}, :valid)
    end

    test "invalid changeset missing required params", %{user1: user1, course2: course2} do
      assert_changeset(%{user_id: user1.id, course_id: course2.id}, :invalid)
      assert_changeset(%{user_id: user1.id, role: :avenger}, :invalid)
      assert_changeset(%{course_id: course2.id, role: :avenger}, :invalid)
    end

    test "invalid changeset bad params", %{
      user1: user1,
      course2: course2
    } do
      assert_changeset(%{user_id: user1.id, course_id: course2.id, role: :avenger}, :invalid)
    end

    test "invalid changeset repeated records", %{
      user1: user1,
      course1: course1
    } do
      changeset =
        CourseRegistration.changeset(%CourseRegistration{}, %{
          course_id: course1.id,
          user_id: user1.id,
          role: :student
        })

      {:ok, course_reg} = Repo.insert(changeset)

      {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               user_id:
                 {"has already been taken",
                  [
                    {:constraint, :unique},
                    {:constraint_name, "course_registrations_user_id_course_id_index"}
                  ]}
             ]

      refute changeset.valid?
    end
  end
end
