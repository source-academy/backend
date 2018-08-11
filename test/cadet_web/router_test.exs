defmodule CadetWeb.RouterTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Router

  test "Swagger", %{conn: conn} do
    Router.swagger_info()
    conn = get(conn, "/swagger/index.html")
    assert response(conn, 200)
  end
end
