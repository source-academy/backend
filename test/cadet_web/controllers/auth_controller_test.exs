defmodule CadetWeb.AuthControllerTest do
  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Cadet.Factory
  import Mock

  alias Cadet.Auth.Guardian
  alias CadetWeb.AuthController

  setup_all do
    HTTPoison.start()
  end

  test "swagger" do
    AuthController.swagger_definitions()
    AuthController.swagger_path_create(nil)
    AuthController.swagger_path_refresh(nil)
    AuthController.swagger_path_logout(nil)
  end

  describe "POST /auth/login" do
    test "success", %{conn: conn} do
      conn =
        post(conn, "/v2/auth/login", %{
          "code" => "student_code",
          "provider" => "test",
          "redirect_uri" => "",
          "client_id" => ""
        })

      assert response(conn, 200)
    end

    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v2/auth/login", %{})

      assert response(conn, 400) == "Missing parameter"
    end

    test "invalid code", %{conn: conn} do
      conn =
        post(conn, "/v2/auth/login", %{
          "code" => "invalid code",
          "provider" => "test",
          "redirect_uri" => "",
          "client_id" => ""
        })

      assert response(conn, 400) == "Unable to validate token: Invalid code"
    end

    test_with_mock "upstream error from Provider.authorise",
                   %{conn: conn},
                   Cadet.Auth.Provider,
                   [],
                   authorise: fn _ -> {:error, :upstream, "Upstream error"} end do
      conn =
        post(conn, "/v2/auth/login", %{
          "code" => "invalid code",
          "provider" => "test",
          "redirect_uri" => "",
          "client_id" => ""
        })

      assert response(conn, 400) ==
               "Unable to retrieve token from authentication provider: Upstream error"
    end

    test_with_mock "unknown error from Provider.authorise",
                   %{conn: conn},
                   Cadet.Auth.Provider,
                   [],
                   authorise: fn _ -> {:error, :other, "Unknown error"} end do
      conn =
        post(conn, "/v2/auth/login", %{
          "code" => "code",
          "provider" => "test",
          "redirect_uri" => "",
          "client_id" => ""
        })

      assert response(conn, 500) == "Unknown error: Unknown error"
    end

    test_with_mock "failure in Accounts.sign_in",
                   %{conn: conn},
                   Cadet.Accounts,
                   [],
                   sign_in: fn _, _, _ -> {:error, :internal_server_error, "Unknown error"} end do
      conn =
        post(conn, "/v2/auth/login", %{
          "code" => "student_code",
          "provider" => "test",
          "redirect_uri" => "",
          "client_id" => ""
        })

      assert response(conn, 500) == "Unable to retrieve user: Unknown error"
    end
  end

  describe "GET /auth/saml_redirect" do
    test_with_mock "success", %{conn: conn}, Samly, [],
      get_active_assertion: fn _ ->
        %{attributes: %{"SamAccountName" => "username", "DisplayName" => "name"}}
      end do
      conn = get(conn, "/v2/auth/saml_redirect", %{"provider" => "saml"})

      assert response(conn, 302)
    end

    test_with_mock "missing parameter", %{conn: conn}, Samly, [],
      get_active_assertion: fn _ ->
        %{attributes: %{"SamAccountName" => "username", "DisplayName" => "name"}}
      end do
      conn = get(conn, "/v2/auth/saml_redirect", %{})

      assert response(conn, 400) == "Missing parameter"
    end

    test_with_mock "missing SAML assertion", %{conn: conn}, Samly, [],
      get_active_assertion: fn _ -> nil end do
      conn = get(conn, "/v2/auth/saml_redirect", %{"provider" => "saml"})

      assert response(conn, 400) == "Unable to validate token: Missing SAML assertion!"
    end

    test_with_mock "missing name attribute", %{conn: conn}, Samly, [],
      get_active_assertion: fn _ -> %{attributes: %{"SamAccountName" => "username"}} end do
      conn = get(conn, "/v2/auth/saml_redirect", %{"provider" => "saml"})

      assert response(conn, 400) == "Unable to validate token: Missing name attribute!"
    end

    test_with_mock "missing username attribute", %{conn: conn}, Samly, [],
      get_active_assertion: fn _ -> %{attributes: %{"DisplayName" => "name"}} end do
      conn = get(conn, "/v2/auth/saml_redirect", %{"provider" => "saml"})

      assert response(conn, 400) == "Unable to validate token: Missing username attribute!"
    end
  end

  describe "POST /auth/refresh" do
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v2/auth/refresh", %{})

      assert response(conn, 400) == "Missing parameter"
    end

    test "invalid token", %{conn: conn} do
      conn = post(conn, "/v2/auth/refresh", %{"refresh_token" => "asdasd"})

      assert response(conn, 401)
    end

    test "valid refresh token", %{conn: conn} do
      user = insert(:user)

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {1, :week})

      resp =
        conn
        |> post("/v2/auth/refresh", %{"refresh_token" => refresh_token})
        |> json_response(200)

      assert %{"access_token" => access_token, "refresh_token" => refresh_token} = resp
      assert {:ok, _} = Guardian.decode_and_verify(access_token)
      assert {:ok, _} = Guardian.decode_and_verify(refresh_token)
    end

    test "access token fails", %{conn: conn} do
      user = insert(:user)

      {:ok, access_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: {1, :day})

      conn = post(conn, "/v2/auth/refresh", %{"refresh_token" => access_token})

      assert response(conn, 401) == "Invalid refresh token"
    end

    test "expired refresh token", %{conn: conn} do
      user = insert(:user)

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {-1, :week})

      conn = post(conn, "/v2/auth/refresh", %{"refresh_token" => refresh_token})

      assert response(conn, 401) == "Invalid refresh token"
    end
  end

  describe "POST /auth/logout" do
    test "missing parameter", %{conn: conn} do
      conn = post(conn, "/v2/auth/logout", %{})

      assert response(conn, 400) == "Missing parameter"
    end

    test "invalid token", %{conn: conn} do
      conn = post(conn, "/v2/auth/logout", %{"refresh_token" => "asdasd"})

      assert response(conn, 401)
    end

    test "valid token", %{conn: conn} do
      user = insert(:user)

      {:ok, refresh_token, _} =
        Guardian.encode_and_sign(user, %{}, token_type: "refresh", ttl: {1, :week})

      conn = post(conn, "/v2/auth/logout", %{"refresh_token" => refresh_token})

      assert response(conn, 200)
      assert {:error, _} = Guardian.decode_and_verify(refresh_token)
    end
  end
end
