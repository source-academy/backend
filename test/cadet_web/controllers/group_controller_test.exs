defmodule CadetWeb.GroupsControllerTest do
  use CadetWeb.ConnCase

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /, student only" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) == "Unauthorized"
    end
  end

  describe "GET /, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      avenger = insert(:user, %{name: "avenger", role: :staff})
      mentor = insert(:user, %{name: "mentor", role: :staff})
      group = insert(:group, %{leader: avenger, mentor: mentor})
      conn = get(conn, build_url())
      group_name = group.name
      group_id = group.id
      expected = [%{"id" => group_id, "avengerName" => "avenger", "groupName" => group_name}]
      assert json_response(conn, 200) == expected
    end
  end

  defp build_url, do: "/v1/groups/"
end
