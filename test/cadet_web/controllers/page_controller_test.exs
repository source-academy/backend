defmodule CadetWeb.PageControllerTest do
  use CadetWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Source Academy"
  end
end
