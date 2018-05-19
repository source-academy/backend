defmodule CadetWeb.AuthControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.AuthController

  test "swagger" do
    AuthController.swagger_definitions()
    AuthController.swagger_path_create(nil)
    AuthController.swagger_path_refresh(nil)
    AuthController.swagger_path_logout(nil)
  end

  describe "POST /v1/auth" do
    test "blank email", %{conn: conn} do
      conn = post(conn, "/v1/auth", %{
        "login" => %{ "email" => "", "password" => "password" }
      })

      assert response(conn, 404)
    end

    test "blank password", %{conn: conn} do
      conn = post(conn, "/v1/auth", %{
        "login" => %{ "email" => "test@test.com", "password" => "" }
      })

      assert response(conn, 404)
    end

    test "email not found", %{conn: conn} do
      conn = post(conn, "/v1/auth", %{
        "login" => %{ "email" => "unknown@test.com", "password" => "password" }
      })

      assert response(conn, 403)
    end

  end

  describe "POST /auth/refresh" do

  end

  describe "POST /auth/logout" do

  end
end
