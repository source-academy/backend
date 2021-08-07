defmodule Cadet.Accounts.CourseRegistrationTest do
  alias Cadet.Accounts.{CourseRegistration, CourseRegistrations, User}

  use Cadet.ChangesetCase, entity: CourseRegistration

  alias Cadet.Repo
  alias Cadet.Assessments.{Submission, Answer}

  setup do
    user1 = insert(:user, %{name: "user 1"})
    user2 = insert(:user, %{name: "user 2"})
    group1 = insert(:group, %{name: "group 1"})
    group2 = insert(:group, %{name: "group 2"})
    course1 = insert(:course, %{course_short_name: "course 1"})
    course2 = insert(:course, %{course_short_name: "course 2"})

    changeset =
      CourseRegistration.changeset(%CourseRegistration{}, %{
        course_id: course1.id,
        user_id: user1.id,
        group_id: group1.id,
        role: :student
      })

    {:ok, _course_reg} = Repo.insert(changeset)

    {:ok,
     %{
       user1: user1,
       user2: user2,
       group1: group1,
       group2: group2,
       course1: course1,
       course2: course2,
       changeset: changeset
     }}
  end

  describe "Changesets:" do
    test "valid changeset", %{
      user1: user1,
      user2: user2,
      course1: course1,
      course2: course2
    } do
      assert_changeset(%{user_id: user1.id, course_id: course2.id, role: :admin}, :valid)

      assert_changeset(
        %{user_id: user2.id, course_id: course1.id, role: :student, agreed_to_research: true},
        :valid
      )

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
      assert CourseRegistrations.get_courses(user2) == []
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
      assert CourseRegistrations.get_users(course2.id) == []
    end

    test "of a group in a course succeeds", %{
      user1: user1,
      user2: user2,
      group1: group1,
      group2: group2,
      course1: course1
    } do
      changeset2 =
        CourseRegistration.changeset(%CourseRegistration{}, %{
          course_id: course1.id,
          user_id: user2.id,
          group_id: group2.id,
          role: :student
        })

      {:ok, _course_reg} = Repo.insert(changeset2)
      course_reg_course1_group1 = CourseRegistrations.get_users(course1.id, group1.id)
      assert length(course_reg_course1_group1) == 1
      [hd | _] = course_reg_course1_group1
      assert user1.id == hd.user_id
      assert group1.id == hd.group_id
      assert course1.id == hd.course_id
    end

    test "of a group in a course failed due to invalid id", %{course1: course1} do
      group2 = insert(:group, %{name: "group2"})
      assert CourseRegistrations.get_users(course1.id, group2.id) == []
    end
  end

  describe "upsert_users_in_course" do
    # Note: roles are already validated in the controller
    test "successful", %{course2: course2} do
      user = insert(:user, %{username: "existing-user"})
      insert(:course_registration, %{course: course2, user: user})
      assert length(CourseRegistrations.get_users(course2.id)) == 1

      usernames_and_roles = [
        %{username: "existing-user", role: "admin"},
        %{username: "student1", role: "student"},
        %{username: "student2", role: "student"},
        %{username: "staff1", role: "staff"},
        %{username: "admin1", role: "admin"}
      ]

      assert :ok ==
               CourseRegistrations.upsert_users_in_course("test", usernames_and_roles, course2.id)

      assert length(CourseRegistrations.get_users(course2.id)) == 5
    end

    test "successful when there are duplicate inputs in list", %{course2: course2} do
      user = insert(:user, %{username: "existing-user"})
      insert(:course_registration, %{course: course2, user: user})
      assert length(CourseRegistrations.get_users(course2.id)) == 1

      usernames_and_roles = [
        %{username: "existing-user", role: "admin"},
        %{username: "student1", role: "student"},
        %{username: "student1", role: "student"},
        %{username: "staff1", role: "staff"},
        %{username: "admin1", role: "admin"}
      ]

      assert :ok ==
               CourseRegistrations.upsert_users_in_course("test", usernames_and_roles, course2.id)

      assert length(CourseRegistrations.get_users(course2.id)) == 4
    end
  end

  describe "enroll course" do
    test "successful enrollment", %{course1: course1, user2: user2} do
      assert length(CourseRegistrations.get_users(course1.id)) == 1

      {:ok, course_reg} =
        CourseRegistrations.enroll_course(%{
          user_id: user2.id,
          course_id: course1.id,
          role: :student
        })

      assert length(CourseRegistrations.get_users(course1.id)) == 2
      assert course_reg.user_id == user2.id
      assert course_reg.course_id == course1.id

      assert User |> where(id: ^user2.id) |> Repo.one() |> Map.fetch!(:latest_viewed_course_id) ==
               course1.id
    end

    test "fail due to invalid changeset", %{course1: course1, user2: user2} do
      {:error, changeset} =
        CourseRegistrations.enroll_course(%{
          user_id: user2.id,
          course_id: course1.id,
          role: :avenger
        })

      refute changeset.valid?
    end
  end

  describe "update course_registration" do
    test "successful insert", %{course1: course1, user2: user2} do
      assert length(CourseRegistrations.get_users(course1.id)) == 1

      {:ok, course_reg} =
        CourseRegistrations.insert_or_update_course_registration(%{
          user_id: user2.id,
          course_id: course1.id,
          role: :student
        })

      assert length(CourseRegistrations.get_users(course1.id)) == 2
      assert course_reg.user_id == user2.id
      assert course_reg.course_id == course1.id
    end

    test "successfully update role", %{course1: course1, user1: user1, group1: group1} do
      assert length(CourseRegistrations.get_users(course1.id)) == 1

      {:ok, course_reg} =
        CourseRegistrations.insert_or_update_course_registration(%{
          user_id: user1.id,
          course_id: course1.id,
          role: :staff
        })

      assert length(CourseRegistrations.get_users(course1.id)) == 1
      assert course_reg.user_id == user1.id
      assert course_reg.course_id == course1.id
      assert course_reg.role == :staff
      assert course_reg.group_id == group1.id
    end

    test "successfully update group", %{course1: course1, user1: user1, group2: group2} do
      assert length(CourseRegistrations.get_users(course1.id)) == 1

      {:ok, course_reg} =
        CourseRegistrations.insert_or_update_course_registration(%{
          user_id: user1.id,
          course_id: course1.id,
          role: :student,
          group_id: group2.id
        })

      assert length(CourseRegistrations.get_users(course1.id)) == 1
      assert course_reg.user_id == user1.id
      assert course_reg.course_id == course1.id
      assert course_reg.role == :student
      assert course_reg.group_id == group2.id
    end

    test "failed due to incomplete changeset", %{course1: course1, user2: user2} do
      assert length(CourseRegistrations.get_users(course1.id)) == 1

      assert_raise FunctionClauseError, fn ->
        CourseRegistrations.insert_or_update_course_registration(%{
          user_id: user2.id,
          course_id: course1.id
        })
      end

      assert length(CourseRegistrations.get_users(course1.id)) == 1
    end
  end

  describe "update_role" do
    setup do
      student = insert(:course_registration, %{role: :student})
      staff = insert(:course_registration, %{role: :staff})
      admin = insert(:course_registration, %{role: :admin})

      {:ok, %{student: student, staff: staff, admin: admin}}
    end

    test "succeeds for student to staff", %{student: %{id: coursereg_id}} do
      {:ok, updated_coursereg} = CourseRegistrations.update_role("staff", coursereg_id)
      assert updated_coursereg.role == :staff
    end

    test "succeeds for student to admin", %{student: %{id: coursereg_id}} do
      {:ok, updated_coursereg} = CourseRegistrations.update_role("admin", coursereg_id)
      assert updated_coursereg.role == :admin
    end

    test "succeeds for admin to staff", %{admin: %{id: coursereg_id}} do
      {:ok, updated_coursereg} = CourseRegistrations.update_role("staff", coursereg_id)
      assert updated_coursereg.role == :staff
    end

    test "fails when invalid role is provided", %{student: %{id: coursereg_id}} do
      assert {:error, {:bad_request, "role is invalid"}} ==
               CourseRegistrations.update_role("invalidrole", coursereg_id)
    end

    test "fails when course registration does not exist", %{} do
      assert {:error, {:bad_request, "User course registration does not exist"}} ==
               CourseRegistrations.update_role("staff", 10_000)
    end
  end

  describe "delete_course_registration" do
    setup do
      student = insert(:course_registration, %{role: :student})
      assessment = insert(:assessment)
      submission = insert(:submission, %{assessment: assessment, student: student})
      question = insert(:question, %{assessment: assessment})
      insert(:answer, %{submission: submission, question: question})

      {:ok, %{student: student, submission: submission}}
    end

    test "succeeds", %{student: %{id: coursereg_id}, submission: %{id: submission_id}} do
      refute is_nil(Submission |> where(student_id: ^coursereg_id) |> Repo.one())
      refute is_nil(Answer |> where(submission_id: ^submission_id) |> Repo.one())
      {:ok, _deleted_coursereg} = CourseRegistrations.delete_course_registration(coursereg_id)
      assert is_nil(CourseRegistration |> where(id: ^coursereg_id) |> Repo.one())
      assert is_nil(Submission |> where(student_id: ^coursereg_id) |> Repo.one())
      assert is_nil(Answer |> where(submission_id: ^submission_id) |> Repo.one())
    end

    test "fails when course registration does not exist", %{} do
      assert {:error, {:bad_request, "User course registration does not exist"}} ==
               CourseRegistrations.delete_course_registration(10_000)
    end
  end

  describe "update_research_agreement" do
    setup do
      student1 = insert(:course_registration, %{role: :student})
      student2 = insert(:course_registration, %{role: :student, agreed_to_research: false})

      {:ok, %{student1: student1, student2: student2}}
    end

    test "succeeds when field is initially nil", %{student1: student1} do
      assert is_nil(
               CourseRegistration
               |> where(id: ^student1.id)
               |> Repo.one()
               |> Map.fetch!(:agreed_to_research)
             )

      CourseRegistrations.update_research_agreement(student1, true)

      assert CourseRegistration
             |> where(id: ^student1.id)
             |> Repo.one()
             |> Map.fetch!(:agreed_to_research) == true
    end

    test "succeeds when field is initially not nil", %{student2: student2} do
      assert CourseRegistration
             |> where(id: ^student2.id)
             |> Repo.one()
             |> Map.fetch!(:agreed_to_research) == false

      CourseRegistrations.update_research_agreement(student2, true)

      assert CourseRegistration
             |> where(id: ^student2.id)
             |> Repo.one()
             |> Map.fetch!(:agreed_to_research) == true
    end
  end
end
