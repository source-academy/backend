defmodule CadetWeb.AuthControllerTest do
  @moduledoc """
  Some tests in this module use pre-recorded HTTP responses saved by ExVCR.
  this allows testing without the use of actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the two config variables `:ivle_key` (used as a module attribute in
  `Cadet.Accounts.IVLE`) and TOKEN (used here). Don't forget to delete the
  cassette files, otherwise ExVCR will not override the cassettes.

  Token refers to the user's authentication token. Please see the IVLE API docs:
  https://wiki.nus.edu.sg/display/ivlelapi/Getting+Started
  To quickly obtain a token, simply supply a dummy url to a login call:
      https://ivle.nus.edu.sg/api/login/?apikey=YOUR_API_KEY&url=http://localhost
  then copy down the token from your browser's address bar.
  """

  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Cadet.Factory

  alias Cadet.Auth.Guardian
  alias CadetWeb.AuthController

  @token if System.get_env("TOKEN"), do: System.get_env("TOKEN"), else: "token"

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
      use_cassette "auth_controller/v1/auth#2" do
        conn =
          post(conn, "/v1/auth", %{
            "login" => %{"ivle_token" => @token <> "Z"}
          })

        assert response(conn, 400)
      end
    end

    test "invalid nusnet id", %{conn: conn} do
      # an invalid nusnet id == ~s("") is typically caught by IVLE.fetch_nusnet_id
      # the custom cassette skips this step so that we can test Accounts.sign_in
      use_cassette "auth_controller/v1/auth#1", custom: true do
        conn =
          post(conn, "/v1/auth", %{
            "login" => %{"ivle_token" => "token"}
          })

        assert response(conn, 400)
      end
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
