defmodule CadetWeb.AdminUserControllerTest do
  use CadetWeb.ConnCase

  import Ecto.Query
  import Cadet.{Factory, TestEntityHelper}

  alias CadetWeb.AdminUserController
  alias Cadet.Repo
  alias Cadet.Courses.{Course, Group}
  alias Cadet.Accounts.CourseRegistration

  test "swagger" do
    assert is_map(AdminUserController.swagger_definitions())
    assert is_map(AdminUserController.swagger_path_index(nil))
    assert is_map(AdminUserController.swagger_path_upsert_users_and_groups(nil))
    assert is_map(AdminUserController.swagger_path_update_role(nil))
    assert is_map(AdminUserController.swagger_path_delete_user(nil))
    assert is_map(AdminUserController.swagger_path_combined_total_xp(nil))
  end

  describe "GET /v2/courses/{course_id}/admin/users" do
    @tag authenticate: :staff
    test "success, when staff retrieves all users", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      group = insert(:group, %{course: course})
      cr1 = conn.assigns[:test_cr]
      cr2 = insert(:course_registration, %{role: :student, course: course, group: group})
      cr3 = insert(:course_registration, %{role: :staff, course: course, group: group})

      expected = [
        %{
          "courseRegId" => cr1.id,
          "course_id" => course_id,
          "group" => nil,
          "name" => cr1.user.name,
          "provider" => "test",
          "role" => "staff",
          "username" => cr1.user.username
        },
        %{
          "courseRegId" => cr2.id,
          "course_id" => course_id,
          "group" => group.name,
          "name" => cr2.user.name,
          "provider" => "test",
          "role" => "student",
          "username" => cr2.user.username
        },
        %{
          "courseRegId" => cr3.id,
          "course_id" => course_id,
          "group" => group.name,
          "name" => cr3.user.name,
          "provider" => "test",
          "role" => "staff",
          "username" => cr3.user.username
        }
      ]

      resp =
        conn
        |> get(build_url_users(course_id))
        |> json_response(200)

      assert expected == Enum.sort(resp, &(&1["courseRegId"] < &2["courseRegId"]))
    end

    @tag authenticate: :staff
    test "can filter by role", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      group = insert(:group, %{course: course})
      insert(:course_registration, %{role: :student, course: course, group: group})
      insert(:course_registration, %{role: :staff, course: course, group: group})

      resp =
        conn
        |> get(build_url_users(course_id) <> "?role=student")
        |> json_response(200)

      assert 1 == Enum.count(resp)
      assert "student" == List.first(resp)["role"]
    end

    @tag authenticate: :staff
    test "can filter by group", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      group = insert(:group, %{course: course})
      insert(:course_registration, %{role: :student, course: course, group: group})
      insert(:course_registration, %{role: :staff, course: course, group: group})

      resp =
        conn
        |> get(build_url_users(course_id) <> "?group=#{group.name}")
        |> json_response(200)

      assert 2 == Enum.count(resp)
      assert group.name == List.first(resp)["group"]
    end

    @tag authenticate: :student
    test "forbidden, when student retrieves users", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      assert conn
             |> get(build_url_users(course_id))
             |> response(403)
    end

    test "401 when not logged in", %{conn: conn} do
      course = insert(:course)

      assert conn
             |> get(build_url_users(course.id))
             |> response(401)
    end
  end

  describe "PUT /v2/courses/{course_id}/admin/users" do
    @tag authenticate: :admin
    test "successfully namespaces and inserts users, and assign groups", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user = insert(:user, %{provider: "test", username: "existing-user"})
      insert(:course_registration, %{course: course, user: user})

      assert CourseRegistration |> where(course_id: ^course_id) |> Repo.all() |> Enum.count() == 2
      assert Group |> Repo.all() |> Enum.count() == 0

      params = %{
        users: [
          %{"username" => "existing-user", "role" => "student", "group" => "group1"},
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student", "group" => "group2"},
          %{"username" => "student3", "role" => "student", "group" => "group2"},
          %{"username" => "staff", "role" => "staff", "group" => "group1"},
          %{"username" => "admin", "role" => "admin", "group" => "group2"}
        ],
        provider: "test"
      }

      resp = put(conn, build_url_users(course_id), params)

      assert response(resp, 200) == "OK"

      # Users inserted
      assert CourseRegistration |> where(course_id: ^course_id) |> Repo.all() |> Enum.count() == 7

      # Groups created
      assert Group |> Repo.all() |> Enum.count() == 2
    end

    @tag authenticate: :admin
    test "successful with duplicate inputs", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user = insert(:user, %{provider: "test", username: "existing-user"})
      insert(:course_registration, %{course: course, user: user})

      assert CourseRegistration |> where(course_id: ^course_id) |> Repo.all() |> Enum.count() == 2

      params = %{
        users: [
          %{"username" => "existing-user", "role" => "student", "group" => "group1"},
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student", "group" => "group2"},
          %{"username" => "student2", "role" => "student", "group" => "group2"},
          %{"username" => "staff", "role" => "staff", "group" => "group1"},
          %{"username" => "admin", "role" => "admin", "group" => "group2"}
        ],
        provider: "test"
      }

      resp = put(conn, build_url_users(course_id), params)

      assert response(resp, 200) == "OK"

      assert CourseRegistration |> where(course_id: ^course_id) |> Repo.all() |> Enum.count() == 6
    end

    @tag authenticate: :staff
    test "fails when not admin", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        users: [
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student"},
          %{"username" => "student3", "role" => "student"},
          %{"username" => "staff", "role" => "staff"},
          %{"username" => "admin", "role" => "admin"}
        ],
        provider: "test"
      }

      conn = put(conn, build_url_users(course_id), params)

      assert response(conn, 403) == "User is not permitted to add users"
    end

    @tag authenticate: :admin
    test "fails when invalid provider is specified", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        users: [
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student"},
          %{"username" => "student3", "role" => "student"},
          %{"username" => "staff", "role" => "staff"},
          %{"username" => "admin", "role" => "admin"}
        ],
        provider: "invalid-provider"
      }

      conn = put(conn, build_url_users(course_id), params)

      assert response(conn, 400) == "Invalid authentication provider"
    end

    @tag authenticate: :admin
    test "fails when no username is specified for at least one input", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        users: [
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student"},
          %{"username" => "student3", "role" => "student"},
          %{"username" => "staff", "role" => "staff"},
          %{"role" => "admin"}
        ],
        provider: "test"
      }

      conn = put(conn, build_url_users(course_id), params)

      assert response(conn, 400) == "Invalid username(s) provided"
    end

    @tag authenticate: :admin
    test "fails when invalid username is specified (not string)", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        users: [
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student"},
          %{"username" => "student3", "role" => "student"},
          %{"username" => "staff", "role" => "staff"},
          %{"username" => nil, "role" => "admin"}
        ],
        provider: "test"
      }

      conn = put(conn, build_url_users(course_id), params)

      assert response(conn, 400) == "Invalid username(s) provided"
    end

    @tag authenticate: :admin
    test "fails when invalid username is specified (empty string)", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        users: [
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student"},
          %{"username" => "student3", "role" => "student"},
          %{"username" => "staff", "role" => "staff"},
          %{"username" => "", "role" => "admin"}
        ],
        provider: "test"
      }

      conn = put(conn, build_url_users(course_id), params)

      assert response(conn, 400) == "Invalid username(s) provided"
    end

    @tag authenticate: :admin
    test "fails when no role is specified for at least one input", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        users: [
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student"},
          %{"username" => "student3", "role" => "student"},
          %{"username" => "staff", "role" => "staff"},
          %{"username" => "admin"}
        ],
        provider: "test"
      }

      conn = put(conn, build_url_users(course_id), params)

      assert response(conn, 400) == "Invalid role(s) provided"
    end

    @tag authenticate: :admin
    test "fails when invalid role is specified for at least one input", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        users: [
          %{"username" => "student1", "role" => "student"},
          %{"username" => "student2", "role" => "student"},
          %{"username" => "student3", "role" => "invalid-role"},
          %{"username" => "staff", "role" => "staff"},
          %{"username" => "admin", "role" => "admin"}
        ],
        provider: "test"
      }

      conn = put(conn, build_url_users(course_id), params)

      assert response(conn, 400) == "Invalid role(s) provided"
    end

    @tag authenticate: :admin
    test "fails when more than 1500", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user = insert(:user, %{provider: "test", username: "existing-user"})
      insert(:course_registration, %{course: course, user: user})

      assert CourseRegistration |> where(course_id: ^course_id) |> Repo.all() |> Enum.count() == 2

      params = %{
        users:
          1..1499
          |> Enum.to_list()
          |> Enum.map(fn x ->
            %{
              "username" => "user" <> Integer.to_string(x),
              "role" => "student",
              "group" => "group1"
            }
          end),
        provider: "test"
      }

      resp = put(conn, build_url_users(course_id), params)

      assert response(resp, 400) == "A course can have maximum of 1500 users"

      assert CourseRegistration |> where(course_id: ^course_id) |> Repo.all() |> Enum.count() == 2
    end
  end

  describe "PUT /v2/courses/{course_id}/admin/users/{course_reg_id}/role" do
    @tag authenticate: :admin
    test "success (student to staff), when admin is admin of the course the user is in", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      params = %{
        "role" => "staff"
      }

      resp = put(conn, build_url_users_role(course_id, user_course_reg.id), params)

      assert response(resp, 200) == "OK"
      updated_course_reg = Repo.get(CourseRegistration, user_course_reg.id)
      assert updated_course_reg.role == :staff
    end

    @tag authenticate: :admin
    test "success (staff to student), when admin is admin of the course the user is in", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :staff, course: course})

      params = %{
        "role" => "student"
      }

      resp = put(conn, build_url_users_role(course_id, user_course_reg.id), params)

      assert response(resp, 200) == "OK"
      updated_course_reg = Repo.get(CourseRegistration, user_course_reg.id)
      assert updated_course_reg.role == :student
    end

    @tag authenticate: :admin
    test "success (admin to staff), when admin is admin of the course the user is in", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :admin, course: course})

      params = %{
        "role" => "staff"
      }

      resp = put(conn, build_url_users_role(course_id, user_course_reg.id), params)

      assert response(resp, 200) == "OK"
      updated_course_reg = Repo.get(CourseRegistration, user_course_reg.id)
      assert updated_course_reg.role == :staff
    end

    @tag authenticate: :admin
    test "fails, when course registration does not exist", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      params = %{
        "role" => "staff"
      }

      conn = put(conn, build_url_users_role(course_id, 10_000), params)

      assert response(conn, 400) == "User course registration does not exist"
    end

    @tag authenticate: :admin
    test "fails, when admin is NOT admin of the course the user is in", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      user_course_reg = insert(:course_registration, %{role: :student})

      params = %{
        "role" => "staff"
      }

      conn = put(conn, build_url_users_role(course_id, user_course_reg.id), params)

      assert response(conn, 403) == "User is in a different course"
      unchanged_course_reg = Repo.get(CourseRegistration, user_course_reg.id)
      assert unchanged_course_reg.role == :student
    end

    @tag authenticate: :staff
    test "fails, when staff attempts to make a role change", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      params = %{
        "role" => "staff"
      }

      conn = put(conn, build_url_users_role(course_id, user_course_reg.id), params)

      assert response(conn, 403) == "Forbidden"
      unchanged_course_reg = Repo.get(CourseRegistration, user_course_reg.id)
      assert unchanged_course_reg.role == :student
    end

    @tag authenticate: :admin
    test "fails, when invalid role is provided", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      params = %{
        "role" => "avenger"
      }

      conn = put(conn, build_url_users_role(course_id, user_course_reg.id), params)

      assert response(conn, 400) == "role is invalid"
      unchanged_course_reg = Repo.get(CourseRegistration, user_course_reg.id)
      assert unchanged_course_reg.role == :student
    end
  end

  describe "DELETE /v2/courses/{course_id}/admin/users/{course_reg_id}" do
    @tag authenticate: :admin
    test "success (delete student), when admin is admin of the course the user is in", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      resp = delete(conn, build_url_users(course_id, user_course_reg.id))

      assert response(resp, 200) == "OK"
      assert Repo.get(CourseRegistration, user_course_reg.id) == nil
    end

    @tag authenticate: :admin
    test "success (delete staff), when admin is admin of the course the user is in", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :staff, course: course})

      resp = delete(conn, build_url_users(course_id, user_course_reg.id))

      assert response(resp, 200) == "OK"
      assert Repo.get(CourseRegistration, user_course_reg.id) == nil
    end

    @tag authenticate: :staff
    test "fails when staff tries to delete user", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      conn = delete(conn, build_url_users(course_id, user_course_reg.id))

      assert response(conn, 403) == "Forbidden"
      assert Repo.get(CourseRegistration, user_course_reg.id) != nil
    end

    @tag authenticate: :admin
    test "fails when admin tries to delete ownself", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      own_course_reg = conn.assigns[:test_cr]

      conn = delete(conn, build_url_users(course_id, own_course_reg.id))

      assert response(conn, 400) == "Admin not allowed to delete ownself from course"
      assert Repo.get(CourseRegistration, own_course_reg.id) != nil
    end

    @tag authenticate: :admin
    test "fails when user course registration does not exist", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]

      conn = delete(conn, build_url_users(course_id, 1))

      assert response(conn, 400) == "User course registration does not exist"
    end

    @tag authenticate: :admin
    test "fails when deleting an admin", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :admin, course: course})

      conn = delete(conn, build_url_users(course_id, user_course_reg.id))

      assert response(conn, 400) == "Admins cannot be deleted"
    end

    @tag authenticate: :admin
    test "fails when deleting a user from another course", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      user_course_reg = insert(:course_registration, %{role: :student})

      conn = delete(conn, build_url_users(course_id, user_course_reg.id))

      assert response(conn, 403) == "User is in a different course"
    end
  end

  describe "GET /v2/courses/{course_id}/admin/users/{course_reg_id}/total_xp" do
    @tag authenticate: :admin
    test "achievement, one completed goal", %{
      conn: conn
    } do
      test_cr = conn.assigns.test_cr
      course = conn.assigns.test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100,
          is_grading_published: true
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        conn
        |> get("/v2/courses/#{course.id}/admin/users/#{test_cr.id}/total_xp")
        |> json_response(200)

      assert resp["totalXp"] == 210
    end
  end

  defp build_url_users(course_id), do: "/v2/courses/#{course_id}/admin/users"

  defp build_url_users(course_id, course_reg_id),
    do: "/v2/courses/#{course_id}/admin/users/#{course_reg_id}"

  defp build_url_users_role(course_id, course_reg_id),
    do: build_url_users(course_id, course_reg_id) <> "/role"
end
