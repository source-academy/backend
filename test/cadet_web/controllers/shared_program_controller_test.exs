defmodule CadetWeb.SharedProgramControllerTest do
  use CadetWeb.ConnCase

  import Cadet.SharedProgramsFixtures

  alias Cadet.SharedPrograms.SharedProgram

  @create_attrs %{
    data: %{},
    uuid: "7488a646-e31f-11e4-aace-600308960662"
  }
  @update_attrs %{
    data: %{},
    uuid: "7488a646-e31f-11e4-aace-600308960668"
  }
  @invalid_attrs %{data: nil, uuid: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all shared_programs", %{conn: conn} do
      conn = get(conn, ~p"/api/shared_programs")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create shared_program" do
    test "renders shared_program when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/shared_programs", shared_program: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/shared_programs/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{},
               "uuid" => "7488a646-e31f-11e4-aace-600308960662"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/shared_programs", shared_program: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update shared_program" do
    setup [:create_shared_program]

    test "renders shared_program when data is valid", %{conn: conn, shared_program: %SharedProgram{id: id} = shared_program} do
      conn = put(conn, ~p"/api/shared_programs/#{shared_program}", shared_program: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/shared_programs/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{},
               "uuid" => "7488a646-e31f-11e4-aace-600308960668"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, shared_program: shared_program} do
      conn = put(conn, ~p"/api/shared_programs/#{shared_program}", shared_program: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete shared_program" do
    setup [:create_shared_program]

    test "deletes chosen shared_program", %{conn: conn, shared_program: shared_program} do
      conn = delete(conn, ~p"/api/shared_programs/#{shared_program}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/shared_programs/#{shared_program}")
      end
    end
  end

  defp create_shared_program(_) do
    shared_program = shared_program_fixture()
    %{shared_program: shared_program}
  end
end
