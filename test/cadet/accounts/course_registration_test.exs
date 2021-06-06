defmodule Cadet.Accounts.CourseRegistrationTest do
  alias Cadet.Accounts.{CourseRegistration, CourseRegistrations}

  use Cadet.ChangesetCase, entity: CourseRegistration

  alias Cadet.Repo

  setup do
    user1 = insert(:user, %{name: "user 1"})
    user2 = insert(:user, %{name: "user 2"})
    # group1 = insert(:group)
    course1 = insert(:course, %{module_code: "course 1"})
    course2 = insert(:course, %{module_code: "course 2"})
    changeset =
        CourseRegistration.changeset(%CourseRegistration{}, %{
          course_id: course1.id,
          user_id: user1.id,
          role: :student
        })

    {:ok, _course_reg} = Repo.insert(changeset)

    {:ok, %{user1: user1, user2: user2, course1: course1, course2: course2, changeset: changeset}}
  end

  describe "Changesets:" do
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

    test "invalid changeset repeated records", %{changeset: changeset} do
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

  describe "get course_registrations" do
    test "of a user succeeds", %{user1: user1, course1: course1, course2: course2} do
      changeset2 =
        CourseRegistration.changeset(%CourseRegistration{}, %{
          course_id: course2.id,
          user_id: user1.id,
          role: :student
        })

      {:ok, _course_reg} = Repo.insert(changeset2)

      course_reg_user1 = CourseRegistrations.get_courses(user1)
      course_reg_user1_course1 = hd(course_reg_user1)
      course_reg_user1_course2 = hd(tl(course_reg_user1))
      assert user1.id == course_reg_user1_course1.user_id
      assert course1.id == course_reg_user1_course1.course_id
      assert user1.id == course_reg_user1_course2.user_id
      assert course2.id == course_reg_user1_course2.course_id
    end

    test "of a user failed due to invalid id", %{user2: user2} do
      assert [] == CourseRegistrations.get_courses(user2)
    end

    test "of a course succeeds", %{user1: user1, user2: user2, course1: course1} do
      changeset2 =
        CourseRegistration.changeset(%CourseRegistration{}, %{
          course_id: course1.id,
          user_id: user2.id,
          role: :student
        })

      {:ok, _course_reg} = Repo.insert(changeset2)

      course_reg_course1 = CourseRegistrations.get_users(course1.id)
      course_reg_course1_user1 = hd(course_reg_course1)
      course_reg_course1_user2 = hd(tl(course_reg_course1))
      assert user1.id == course_reg_course1_user1.user_id
      assert course1.id == course_reg_course1_user1.course_id
      assert user2.id == course_reg_course1_user2.user_id
      assert course1.id == course_reg_course1_user2.course_id
    end

    test "of a course failed due to invalid id", %{course2: course2} do
      assert [] == CourseRegistrations.get_users(course2.id)
    end



    # test "" do

    # end

    # test "" do

    # end
  end
end
