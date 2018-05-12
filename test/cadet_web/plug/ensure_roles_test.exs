defmodule CadetWeb.Plug.EnsureRolesTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Plug.AssignCurrentUser
  alias CadetWeb.Plug.EnsureRoles

  test "init" do
    EnsureRoles.init(%{})
    # nothing to test
  end

  @tag authenticate: :student
  test "logged in as student", %{conn: conn} do
    conn = AssignCurrentUser.call(conn, %{})
    conn = EnsureRoles.call(conn, %{roles: [:admin, :staff]})
    assert html_response(conn, 403) =~ "Not admin/staff"
  end

  @tag authenticate: :staff
  test "logged in as staff", %{conn: conn} do
    conn = AssignCurrentUser.call(conn, %{})
    conn = EnsureRoles.call(conn, %{roles: [:admin, :staff]})
    refute conn.status # conn.status is not set yet
  end

  @tag authenticate: :admin
  test "logged in as admin", %{conn: conn} do
    conn = AssignCurrentUser.call(conn, %{})
    conn = EnsureRoles.call(conn, %{roles: [:admin, :staff]})
    refute conn.status # conn.status is not set yet
  end
end
