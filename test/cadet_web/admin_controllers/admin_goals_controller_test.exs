defmodule CadetWeb.AdminGoalsControllerTest do
  use CadetWeb.ConnCase

  import Cadet.TestEntityHelper

  alias Cadet.Repo
  alias Cadet.Incentives.Goal
  alias CadetWeb.AdminGoalsController
  alias Ecto.UUID

  test "swagger" do
    assert is_map(AdminGoalsController.swagger_path_index(nil))
    assert is_map(AdminGoalsController.swagger_path_index(nil))
    assert is_map(AdminGoalsController.swagger_path_update(nil))
    assert is_map(AdminGoalsController.swagger_path_bulk_update(nil))
    assert is_map(AdminGoalsController.swagger_path_delete(nil))
  end

  describe "GET /admin/goals" do
    setup do
      {:ok, g} = %Goal{uuid: UUID.generate()} |> Map.merge(goal_literal(5)) |> Repo.insert()

      %{goal: g}
    end

    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn, goal: goal} do
      [resp_goal] =
        conn
        |> get(build_path())
        |> json_response(200)

      assert goal_json_literal(5) = resp_goal
      assert resp_goal["uuid"] == goal.uuid
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      conn
      |> get(build_path())
      |> response(403)
    end

    test "401 if unauthenticated", %{conn: conn} do
      conn
      |> get(build_path())
      |> response(401)
    end
  end

  describe "PUT /admin/goals/:uuid" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      uuid = UUID.generate()

      conn
      |> put(build_path(uuid), %{"goal" => goal_json_literal(0)})
      |> response(204)

      ach = Repo.get(Goal, uuid)

      assert goal_literal(0) = ach
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      uuid = UUID.generate()

      conn
      |> put(build_path(uuid), %{"goal" => goal_json_literal(0)})
      |> response(403)

      assert Goal |> Repo.get(uuid) |> is_nil()
    end

    test "401 if unauthenticated", %{conn: conn} do
      uuid = UUID.generate()

      conn
      |> put(build_path(uuid), %{"goal" => goal_json_literal(0)})
      |> response(401)

      assert Goal |> Repo.get(uuid) |> is_nil()
    end
  end

  describe "PUT /admin/goals" do
    setup do
      %{
        goals: [
          Map.merge(goal_json_literal(1), %{"uuid" => UUID.generate()}),
          Map.merge(goal_json_literal(2), %{"uuid" => UUID.generate()})
        ]
      }
    end

    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn, goals: goals = [a1, a2]} do
      conn
      |> put(build_path(), %{
        "goals" => goals
      })
      |> response(204)

      assert goal_literal(1) = Repo.get(Goal, a1["uuid"])
      assert goal_literal(2) = Repo.get(Goal, a2["uuid"])
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn, goals: goals = [a1, a2]} do
      conn
      |> put(build_path(), %{
        "goals" => goals
      })
      |> response(403)

      assert Goal |> Repo.get(a1["uuid"]) |> is_nil()
      assert Goal |> Repo.get(a2["uuid"]) |> is_nil()
    end

    test "401 if unauthenticated", %{conn: conn, goals: goals = [a1, a2]} do
      conn
      |> put(build_path(), %{
        "goals" => goals
      })
      |> response(401)

      assert Goal |> Repo.get(a1["uuid"]) |> is_nil()
      assert Goal |> Repo.get(a2["uuid"]) |> is_nil()
    end
  end

  describe "DELETE /admin/goals/:uuid" do
    setup do
      {:ok, a} = %Goal{uuid: UUID.generate()} |> Map.merge(goal_literal(5)) |> Repo.insert()

      %{goal: a}
    end

    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn, goal: a} do
      conn
      |> delete(build_path(a.uuid))
      |> response(204)

      assert Goal |> Repo.get(a.uuid) |> is_nil()
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn, goal: a} do
      conn
      |> delete(build_path(a.uuid))
      |> response(403)

      assert goal_literal(5) = Repo.get(Goal, a.uuid)
    end

    test "401 if unauthenticated", %{conn: conn, goal: a} do
      conn
      |> delete(build_path(a.uuid))
      |> response(401)

      assert goal_literal(5) = Repo.get(Goal, a.uuid)
    end
  end

  defp build_path(uuid \\ nil)

  defp build_path(nil) do
    "/v1/admin/goals"
  end

  defp build_path(uuid) do
    "/v1/admin/goals/#{uuid}"
  end
end
