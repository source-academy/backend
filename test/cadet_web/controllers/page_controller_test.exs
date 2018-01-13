defmodule CadetWeb.PageControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Auth.Guardian

  describe "Unauthenticated User" do
    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 401) =~ "unauthenticated"
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
