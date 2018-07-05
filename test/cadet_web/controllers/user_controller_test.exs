defmodule CadetWeb.UserControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.UserController

  test "swagger" do
    assert is_map(UserController.swagger_definitions())
    assert is_map(UserController.swagger_path_index(nil))
  end

  describe "GET /user" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/user", nil)
      assert response(conn, 401)
    end
  end
end
