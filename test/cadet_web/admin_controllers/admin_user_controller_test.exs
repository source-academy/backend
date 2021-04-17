defmodule CadetWeb.AdminUserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.AdminUserController

  test "swagger" do
    assert is_map(AdminUserController.swagger_definitions())
    assert is_map(AdminUserController.swagger_path_index(nil))
  end

  describe "GET /admin/users" do
    @tag authenticate: :staff
    test "success, when staff retrieves users", %{conn: conn} do
      insert(:student)

      resp =
        conn
        |> get("/v2/admin/users")
        |> json_response(200)

      assert 2 == Enum.count(resp)
    end

    @tag authenticate: :staff
    test "can filter by role", %{conn: conn} do
      insert(:student)

      resp =
        conn
        |> get("/v2/admin/users?role=student")
        |> json_response(200)

      assert 1 == Enum.count(resp)
      assert "student" == List.first(resp)["role"]
    end

    @tag authenticate: :staff
    test "can filter by group", %{conn: conn} do
      group = insert(:group)
      insert(:student, group: group)

      resp =
        conn
        |> get("/v2/admin/users?group=#{group.name}")
        |> json_response(200)

      assert 1 == Enum.count(resp)
      assert group.name == List.first(resp)["group"]
    end

    @tag authenticate: :student
    test "forbidden, when student retrieves users", %{conn: conn} do
      assert conn
             |> get("/v2/admin/users")
             |> response(403)
    end

    test "401 when not logged in", %{conn: conn} do
      assert conn
             |> get("/v2/admin/users")
             |> response(401)
    end
  end
end
