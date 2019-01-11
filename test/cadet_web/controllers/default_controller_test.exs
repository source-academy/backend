defmodule DefaultControllerTest do
  use CadetWeb.ConnCase

  describe "GET /" do
    test "default root page renders correctly", %{conn: conn} do
      conn = get(conn, "/")
      assert response(conn, 200) === "Welcome to the Source Academy Backend!"
    end
  end
end
