defmodule CadetWeb.PageControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias Cadet.Auth.Guardian

  describe "Unauthenticated User" do
    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 401) =~ "unauthenticated"
    end
  end

  describe "Authenticated User" do
    setup do
      user = insert(:user)

      conn =
        build_conn()
        |> Guardian.Plug.sign_in(user)

      {:ok, [conn: conn]}
    end

    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Source Academy"
    end
  end
end
