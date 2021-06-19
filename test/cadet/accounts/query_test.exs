defmodule Cadet.Accounts.QueryTest do
  use Cadet.DataCase

  alias Cadet.Accounts.Query

  test "all_students" do
    course = insert(:course)
    insert(:course_registration, %{course: course, role: :student})

    result = Query.all_students(course.id)

    assert 1 == Enum.count(result)
  end

  describe "avenger of function:" do
    setup do
      user_a = insert(:user)
      user_b = insert(:user)
      user_c = insert(:user)
      course1 = insert(:course, course_name: "course 1")
      course2 = insert(:course, course_name: "course 2")
      staff_a1 = insert(:course_registration, %{user: user_a, course: course1, role: :staff})
      group1 = insert(:group, %{leader: staff_a1, course: course1})

      student_b1 =
        insert(:course_registration, %{
          user: user_b,
          course: course1,
          role: :student,
          group: group1
        })

      student_c1 = insert(:course_registration, %{user: user_c, course: course1, role: :student})
      staff_a2 = insert(:course_registration, %{user: user_a, course: course2, role: :staff})

      {:ok,
       %{
         c1: course1,
         c2: course2,
         sta_a1: staff_a1,
         stu_b1: student_b1,
         stu_c1: student_c1,
         sta_a2: staff_a2
       }}
    end

    test "true, when in same course same group", %{sta_a1: sta_a1, stu_b1: stu_b1} do
      assert Query.avenger_of?(sta_a1, stu_b1.id)
    end

    test "false, when in same course different group", %{sta_a1: sta_a1, stu_c1: stu_c1} do
      refute Query.avenger_of?(sta_a1, stu_c1.id)
    end

    test "false, when asked by a student", %{sta_a1: sta_a1, stu_b1: stu_b1} do
      refute Query.avenger_of?(stu_b1, sta_a1.id)
    end

    test "false, when asked in different course", %{sta_a2: sta_a2, stu_b1: stu_b1} do
      refute Query.avenger_of?(sta_a2, stu_b1.id)
    end
  end
end
