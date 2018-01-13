defmodule CadetWeb.Plug.AssignCurrentUserTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Plug.AssignCurrentUser

  test "init" do
    AssignCurrentUser.init(%{})
    # nothing to test
  end

  test "not logged in", %{conn: conn} do
    conn = AssignCurrentUser.call(conn, %{})
    assert conn.assigns[:current_user] == nil
  end

  @tag authenticate: :student
  test "logged in", %{conn: conn} do
    conn = AssignCurrentUser.call(conn, %{})
    assert conn.assigns[:current_user] != nil
  end
end
