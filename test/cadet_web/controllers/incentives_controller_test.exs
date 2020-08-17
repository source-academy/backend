defmodule CadetWeb.IncentivesControllerTest do
  use CadetWeb.ConnCase

  import Cadet.{Factory, TestEntityHelper}

  alias Cadet.Repo
  alias CadetWeb.IncentivesController
  alias Cadet.Incentives.GoalProgress

  test "swagger" do
    assert is_map(IncentivesController.swagger_definitions())
    assert is_map(IncentivesController.swagger_path_index_achievements(nil))
    assert is_map(IncentivesController.swagger_path_index_goals(nil))
  end

  describe "GET /achievements" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn} do
      insert(:achievement, achievement_literal(0))

      resp = conn |> get("/v1/achievements") |> json_response(200)

      assert [achievement_json_literal(0)] = resp
    end

    test "401 if unauthenticated", %{conn: conn} do
      conn |> get("/v1/achievements") |> response(401)
    end
  end

  describe "GET /self/goals" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn} do
      insert(:goal, goal_literal(0))

      resp = conn |> get("/v1/self/goals") |> json_response(200)

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
          xp: 123,
          completed: true
        }
        |> Repo.insert()

      [resp_goal] = conn |> get("/v1/self/goals") |> json_response(200)

      assert goal_json_literal(0) = resp_goal
      assert resp_goal["exp"] == progress.xp
      assert resp_goal["completed"] == progress.completed
    end

    test "401 if unauthenticated", %{conn: conn} do
      conn |> get("/v1/self/goals") |> response(401)
    end
  end
end
