defmodule CadetWeb.PageControllerTest do
  use CadetWeb.ConnCase

  describe "Unauthenticated User" do
    test "GET /", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 401) =~ "unauthenticated"
    end
  end
end
