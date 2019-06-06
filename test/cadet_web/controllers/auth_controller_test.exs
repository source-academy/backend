defmodule CadetWeb.AuthControllerTest do
  @moduledoc """
  Some tests in this module use pre-recorded HTTP responses saved by ExVCR.
  this allows testing without the use of actual external LumiNUS API calls.

  In the case that you need to change the recorded responses, you will need
  to set the config variables `luminus_api_key`, `luminus_client_id`,
  `luminus_client_secret` and `luminus_redirect_url` (used as a module attribute
  in `Cadet.Accounts.Luminus`) and environment variable CODE (used here). Don't
  forget to delete the cassette files, otherwise ExVCR will not override the
  cassettes. You can set the CODE environment variable like so,

    CODE=auth_code_goes_here mix test

  Code refers to the authorization code generated via the OAuth Authorization Grant Type.
  More information can be found here
  https://wiki.nus.edu.sg/pages/viewpage.action?pageId=235638755.
  """

  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Cadet.Factory

  alias Cadet.Auth.Guardian
  alias CadetWeb.AuthController

  @code System.get_env("CODE") || "code"

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
            "login" => %{"luminus_code" => @code}
          })

        assert response(conn, 200)
      end
    end

    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth", %{})

      assert response(conn, 400) == "Missing parameter"
    end

    test "blank code", %{conn: conn} do
      conn =
        post(conn, "/v1/auth", %{
          "login" => %{"luminus_code" => ""}
        })

      assert response(conn, 400) == "Missing parameter"
    end

    test "invalid code", %{conn: conn} do
      use_cassette "auth_controller/v1/auth#2" do
        conn =
          post(conn, "/v1/auth", %{
            "login" => %{"luminus_code" => @code <> "Z"}
          })

        assert response(conn, 400) == "Unable to fetch NUSNET ID from LumiNUS."
      end
    end
  end

  describe "POST /auth/refresh" do
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth/refresh", %{})

      assert response(conn, 400) == "Missing parameter"
    end

    test "invalid token", %{conn: conn} do
      conn = post(conn, "/v1/auth/refresh", %{"refresh_token" => "asdasd"})

      assert response(conn, 401)
    end

    test "valid refresh token", %{conn: conn} do
      user = insert(:user)

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {1, :week})

      resp =
        conn
        |> post("/v1/auth/refresh", %{"refresh_token" => refresh_token})
        |> json_response(200)

      assert %{"access_token" => access_token, "refresh_token" => refresh_token} = resp
      assert {:ok, _} = Guardian.decode_and_verify(access_token)
      assert {:ok, _} = Guardian.decode_and_verify(refresh_token)
    end

    test "access token fails", %{conn: conn} do
      user = insert(:user)

      {:ok, access_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {1, :day})

      conn = post(conn, "/v1/auth/refresh", %{"refresh_token" => access_token})

      assert response(conn, 401) == "Invalid Token"
    end

    test "expired refresh token", %{conn: conn} do
      user = insert(:user)

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {-1, :week})

      conn = post(conn, "/v1/auth/refresh", %{"refresh_token" => refresh_token})

      assert response(conn, 401) == "Invalid Token"
    end
  end

  describe "POST /auth/logout" do
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v1/auth/logout", %{})

      assert response(conn, 400) == "Missing parameter"
    end

    test "invalid token", %{conn: conn} do
      conn = post(conn, "/v1/auth/logout", %{"refresh_token" => "asdasd"})

      assert response(conn, 401)
    end

    test "valid token", %{conn: conn} do
      user = insert(:user)

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {1, :week})

      conn = post(conn, "/v1/auth/logout", %{"refresh_token" => refresh_token})

      assert response(conn, 200)
      assert {:error, _} = Guardian.decode_and_verify(refresh_token)
    end
  end
end
