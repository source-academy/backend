defmodule CadetWeb.AdminControllerTest do
  use CadetWeb.ConnCase

  describe "Unauthenticated User" do
    test "GET /admin", %{conn: conn} do
      conn = get(conn, "/admin")
      assert html_response(conn, 401) =~ "unauthenticated"
    end
  end

  @tag authenticate: :student
  describe "Authenticated Student" do
    test "GET /admin", %{conn: conn} do
      conn = get(conn, "/admin")
      assert html_response(conn, 403) =~ "Not admin"
    end
  end

  @tag authenticate: :admin
  describe "Authenticated Admin" do
    test "GET /admin", %{conn: conn} do
      conn = get(conn, "/admin")
      assert html_response(conn, 200) =~ "Admin"
    end
  end
end
