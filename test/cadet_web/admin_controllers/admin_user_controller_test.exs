defmodule CadetWeb.AdminUserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.AdminUserController
  alias Cadet.Repo
  alias Cadet.Courses.Course

  test "swagger" do
    assert is_map(AdminUserController.swagger_definitions())
    assert is_map(AdminUserController.swagger_path_index(nil))
  end

  describe "GET /v2/course/{course_id}/admin/users" do
    @tag authenticate: :staff
    test "success, when staff retrieves all users", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      group = insert(:group, %{course: course})
      insert(:course_registration, %{role: :student, course: course, group: group})
      insert(:course_registration, %{role: :staff, course: course, group: group})

      resp =
        conn
        |> get(build_url(course_id))
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
      |> get(build_url(course_id) <> "?role=student")
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
        |> get(build_url(course_id) <> "?group=#{group.name}")
        |> json_response(200)

      assert 2 == Enum.count(resp)
      assert group.name == List.first(resp)["group"]
    end

    @tag authenticate: :student
    test "forbidden, when student retrieves users", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      assert conn
             |> get(build_url(course_id))
             |> response(403)
    end

    # test "401 when not logged in", %{conn: conn} do
    #   course_id = conn.assigns[:course_id]
    #   assert conn
    #          |> get(build_url(course_id))
    #          |> response(401)
    # end
  end

  defp build_url(course_id), do: "/v2/course/#{course_id}/admin/users"
end
