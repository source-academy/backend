defmodule CadetWeb.AdminUserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.AdminUserController
  alias Cadet.Repo
  alias Cadet.Courses.Course
  alias Cadet.Accounts.CourseRegistration

  test "swagger" do
    assert is_map(AdminUserController.swagger_definitions())
    assert is_map(AdminUserController.swagger_path_index(nil))
  end

  describe "GET /v2/courses/{course_id}/admin/users" do
    @tag authenticate: :staff
    test "success, when staff retrieves all users", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      group = insert(:group, %{course: course})
      insert(:course_registration, %{role: :student, course: course, group: group})
      insert(:course_registration, %{role: :staff, course: course, group: group})

      resp =
        conn
        |> get(build_url_users(course_id))
        |> json_response(200)

      assert 3 == Enum.count(resp)
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

    # test "401 when not logged in", %{conn: conn} do
    #   course_id = conn.assigns[:course_id]
    #   assert conn
    #          |> get(build_url(course_id))
    #          |> response(401)
    # end
  end

  describe "PUT /v2/courses/{course_id}/admin/users/role" do
    @tag authenticate: :admin
    test "success (student to staff), when admin is admin of the course the user is in", %{
      conn: conn
    } do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      params = %{
        "role" => "staff",
        "crId" => user_course_reg.id
      }

      resp = put(conn, build_url_users_role(course_id), params)

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
        "role" => "student",
        "crId" => user_course_reg.id
      }

      resp = put(conn, build_url_users_role(course_id), params)

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
        "role" => "staff",
        "crId" => user_course_reg.id
      }

      resp = put(conn, build_url_users_role(course_id), params)

      assert response(resp, 200) == "OK"
      updated_course_reg = Repo.get(CourseRegistration, user_course_reg.id)
      assert updated_course_reg.role == :staff
    end

    @tag authenticate: :admin
    test "fails, when admin is NOT admin of the course the user is in", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student})

      params = %{
        "role" => "staff",
        "crId" => user_course_reg.id
      }

      conn = put(conn, build_url_users_role(course_id), params)

      assert response(conn, 403) == "Wrong course"
    end

    @tag authenticate: :staff
    test "fails, when staff attempts to make a role change", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      params = %{
        "role" => "staff",
        "crId" => user_course_reg.id
      }

      conn = put(conn, build_url_users_role(course_id), params)

      assert response(conn, 403) == "User is not permitted to change others' roles"
    end

    @tag authenticate: :admin
    test "fails, when invalid role is provided", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      user_course_reg = insert(:course_registration, %{role: :student, course: course})

      params = %{
        "role" => "avenger",
        "crId" => user_course_reg.id
      }

      conn = put(conn, build_url_users_role(course_id), params)

      assert response(conn, 400) == "role is invalid"
    end
  end

  defp build_url_users(course_id), do: "/v2/courses/#{course_id}/admin/users"
  defp build_url_users_role(course_id), do: build_url_users(course_id) <> "/role"
end
