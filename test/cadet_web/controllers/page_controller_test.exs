defmodule CadetWeb.PageControllerTest do
  use CadetWeb.ConnCase

  describe "Unauthenticated User" do
    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert redirected_to(conn) =~ "/session/new"
    end
  end

  @tag authenticate: :student
  describe "Authenticated User" do
    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Source Academy"
    end
  end
end
