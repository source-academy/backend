defmodule CadetWeb.AuthControllerTest do
  @moduledoc """
  Some tests in this module use pre-recorded HTTP responses saved by ExVCR.
  this allows testing without the use of actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the two environment variables IVLE_KEY (used as a module attribute in
  `Cadet.Accounts.IVLE`) and TOKEN (used here). Don't forget to delete the
  cassette files, otherwise ExVCR will not override the cassettes.
  """

  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Cadet.Factory

  alias CadetWeb.AuthController
  alias Cadet.Auth.Guardian

  @token String.replace(inspect(System.get_env("TOKEN")), ~s("), "")

  setup_all do
    HTTPoison.start()
  end

  test "swagger" do
    AuthController.swagger_definitions()
    AuthController.swagger_path_create(nil)
    AuthController.swagger_path_refresh(nil)
    AuthController.swagger_path_logout(nil)
  end

  describe "POST /auth" do
    test "success", %{conn: conn} do
      use_cassette "auth_controller/v1/auth#1" do
        conn =
          post(conn, "/v1/auth", %{
            "login" => %{"ivle_token" => @token}
          })

        assert response(conn, 200)
      end
    end

    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth", %{})

      assert response(conn, 400)
    end

    test "blank token", %{conn: conn} do
      conn =
        post(conn, "/v1/auth", %{
          "login" => %{"ivle_token" => ""}
        })

      assert response(conn, 400)
    end

    test "invalid token", %{conn: conn} do
      conn =
        post(conn, "/v1/auth", %{
          "login" => %{"ivle_token" => @token <> "Z"}
        })

      assert response(conn, 400)
    end
  end

  describe "POST /auth/refresh" do
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth/refresh", %{})

      assert response(conn, 400)
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
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth/logout", %{})

      assert response(conn, 400)
    end

    test "invalid token", %{conn: conn} do
      conn = post(conn, "/v1/auth/logout", %{"access_token" => "asdasd"})

      assert response(conn, 401)
    end

    test "valid token", %{conn: conn} do
      user = insert(:user)

      {:ok, access_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {1, :hour})

      conn = post(conn, "/v1/auth/logout", %{"access_token" => access_token})

      assert response(conn, 200)

      # Also check that refresh_token is now revoked
      assert(elem(Guardian.decode_and_verify(access_token), 0) == :error)
    end
  end
end
