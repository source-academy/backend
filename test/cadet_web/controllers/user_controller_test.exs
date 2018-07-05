defmodule CadetWeb.UserControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.UserController
  alias Cadet.Auth.Guardian

  test "swagger" do
    assert is_map(UserController.swagger_definitions())
    assert is_map(UserController.swagger_path_index(nil))
  end

  describe "GET /user" do
    test "success", %{conn: conn} do
      user = insert(:user, %{role: :student})
      conn = Guardian.Plug.sign_in(conn, user)
      conn = get(conn, "/v1/user", nil)
      assert response(conn, 200)
    end

    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/user", nil)
      assert response(conn, 401)
    end
  end
end
