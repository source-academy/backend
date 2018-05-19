defmodule CadetWeb.AuthControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.AuthController
  alias Cadet.Auth.Guardian

  test "swagger" do
    AuthController.swagger_definitions()
    AuthController.swagger_path_create(nil)
    AuthController.swagger_path_refresh(nil)
    AuthController.swagger_path_logout(nil)
  end

  describe "POST /v1/auth" do
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth", %{})

      assert response(conn, 404)
    end

    test "blank email", %{conn: conn} do
      conn =
        post(conn, "/v1/auth", %{
          "login" => %{"email" => "", "password" => "password"}
        })

      assert response(conn, 404)
    end

    test "blank password", %{conn: conn} do
      conn =
        post(conn, "/v1/auth", %{
          "login" => %{"email" => "test@test.com", "password" => ""}
        })

      assert response(conn, 404)
    end

    test "email not found", %{conn: conn} do
      conn =
        post(conn, "/v1/auth", %{
          "login" => %{"email" => "unknown@test.com", "password" => "password"}
        })

      assert response(conn, 403)
    end

    test "invalid password", %{conn: conn} do
      test_password = "password"
      user = insert(:user)

      email =
        insert(:email, %{
          token: Pbkdf2.hash_pwd_salt(test_password),
          user: user
        })

      conn =
        post(conn, "/v1/auth", %{
          "login" => %{"email" => email.uid, "password" => "password2"}
        })

      assert response(conn, 403)
    end

    test "valid email and password", %{conn: conn} do
      test_password = "password"
      user = insert(:user)

      email =
        insert(:email, %{
          token: Pbkdf2.hash_pwd_salt(test_password),
          user: user
        })

      conn =
        post(conn, "/v1/auth", %{
          "login" => %{
            "email" => email.uid,
            "password" => test_password
          }
        })

      assert json_response(conn, 200)
    end
  end

  describe "POST /auth/refresh" do
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth/refresh", %{})

      assert response(conn, 404)
    end

    test "invalid token", %{conn: conn} do
      conn = post(conn, "/v1/auth/refresh", %{"refresh_token" => "asdasd"})

      assert response(conn, 401)
    end

    test "valid token", %{conn: conn} do
      user = insert(:user)

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {52, :weeks})

      conn = post(conn, "/v1/auth/refresh", %{"refresh_token" => refresh_token})

      assert %{"refresh_token" => ^refresh_token, "access_token" => _} = json_response(conn, 200)
    end
  end

  describe "POST /auth/logout" do
  end
end
