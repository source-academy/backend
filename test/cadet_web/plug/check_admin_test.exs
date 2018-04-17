defmodule CadetWeb.Plug.CheckAdminTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Plug.AssignCurrentUser
  alias CadetWeb.Plug.CheckAdmin

  test "init" do
    CheckAdmin.init(%{})
    # nothing to test
  end

  @tag authenticate: :student
  test "logged in as student", %{conn: conn} do
    conn = AssignCurrentUser.call(conn, %{})
    conn = CheckAdmin.call(conn, %{})
    assert html_response(conn, 403) =~ "Not admin"
  end
end
