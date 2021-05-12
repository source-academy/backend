defmodule CadetWeb.IncentivesControllerTest do
  use CadetWeb.ConnCase

  import Cadet.{Factory, TestEntityHelper}

  alias Cadet.Repo
  alias CadetWeb.IncentivesController
  alias Cadet.Incentives.{Goal, Goals, GoalProgress}
  alias Ecto.UUID

  test "swagger" do
    assert is_map(IncentivesController.swagger_definitions())
    assert is_map(IncentivesController.swagger_path_index_achievements(nil))
    assert is_map(IncentivesController.swagger_path_index_goals(nil))
    assert is_map(IncentivesController.swagger_path_update_progress(nil))
  end

  describe "GET /achievements" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn} do
      insert(:achievement, achievement_literal(0))

      resp = conn |> get("/v2/achievements") |> json_response(200)

      assert [achievement_json_literal(0)] = resp
    end

    test "401 if unauthenticated", %{conn: conn} do
      conn |> get("/v2/achievements") |> response(401)
    end
  end

  describe "GET /self/goals" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn} do
      insert(:goal, goal_literal(0))

      resp = conn |> get("/v2/self/goals") |> json_response(200)

      assert [goal_json_literal(0)] = resp
    end

    @tag authenticate: :student
    test "includes user's progress", %{conn: conn} do
      user = conn.assigns.current_user
      goal = insert(:goal, goal_literal(0))

      {:ok, progress} =
        %GoalProgress{
          goal_uuid: goal.uuid,
          user_id: user.id,
          count: 123,
          completed: true
        }
        |> Repo.insert()

      [resp_goal] = conn |> get("/v2/self/goals") |> json_response(200)

      assert goal_json_literal(0) = resp_goal
      assert resp_goal["count"] == progress.count
      assert resp_goal["completed"] == progress.completed
    end

    test "401 if unauthenticated", %{conn: conn} do
      conn |> get("/v2/self/goals") |> response(401)
    end
  end

  describe "POST /self/goals/:uuid/progress" do
    setup do
      {:ok, g} = %Goal{uuid: UUID.generate()} |> Map.merge(goal_literal(5)) |> Repo.insert()

      %{goal: g}
    end

    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn, goal: g} do
      user = conn.assigns.current_user
      conn
      |> post("/v2/self/goals/#{g.uuid}/progress", %{
        "progress" => %{count: 100, completed: false, userid: user.id, uuid: g.uuid}
      })
      |> response(204)

      retrieved_goal = Goals.get_with_progress(user)
      assert [%{progress: [%{count: 100, completed: false}]}] = retrieved_goal
    end

    test "401 if unauthenticated", %{conn: conn, goal: g} do
      conn
      |> post("/v2/self/goals/#{g.uuid}/progress", %{
        "progress" => %{count: 100, completed: false, userid: 1, uuid: g.uuid}
      })
      |> response(401)
    end
  end
end
