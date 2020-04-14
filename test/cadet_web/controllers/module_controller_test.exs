defmodule CadetWeb.ModuleControllerTest do
  use CadetWeb.ConnCase
  alias CadetWeb.ModuleController

  test "webhook received payload", %{conn: conn} do
    conn = post(conn, "/v1/webhook", %{})

    assert response(conn, 200) == "OK"
  end

  test "Module not found", %{conn: conn} do
    resp = get(conn, "/static/*path", %{})

    assert response(resp, 404) == "Module not found"
  end
end
