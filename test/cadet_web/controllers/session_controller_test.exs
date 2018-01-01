defmodule CadetWeb.SessionControllerTest do
  use CadetWeb.ConnCase

  test "GET /session/new", %{conn: conn} do
    conn = get(conn, "/session/new")
    assert html_response(conn, 200) =~ "Source Academy"
  end

  test "POST /session", %{conn: conn} do
    conn = post(conn, "/session")
    assert html_response(conn, 302) 
  end

  test "DELETE /session/:id", %{conn: conn} do
    conn = delete(conn, "/session/3")
    assert html_response(conn, 302)
  end
end
