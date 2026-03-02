defmodule CadetWeb.RouterTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Router.Helpers
  alias Cadet.TokenExchange

  test "Swagger", %{conn: conn} do
    Router.swagger_info()
    conn = get(conn, "/swagger/index.html")
    assert response(conn, 200)
  end

  describe "route definitions" do
    test "GET /auth/saml_redirect_vscode route exists", %{conn: conn} do
      # This test verifies the route is defined.
      # The actual endpoint behavior is tested in auth_controller_test
      assert Helpers.auth_path(CadetWeb.Endpoint, :saml_redirect_vscode) ==
               "/v2/auth/saml_redirect_vscode"
    end

    test "GET /auth/exchange route exists", %{conn: conn} do
      # This test verifies the route is defined.
      # The actual endpoint behavior is tested in auth_controller_test
      assert Helpers.auth_path(CadetWeb.Endpoint, :exchange) ==
               "/v2/auth/exchange"
    end

    test "POST /auth/refresh route still exists", %{conn: conn} do
      assert Helpers.auth_path(CadetWeb.Endpoint, :refresh) ==
               "/v2/auth/refresh"
    end
  end
end
