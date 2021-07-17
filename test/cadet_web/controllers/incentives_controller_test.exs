defmodule CadetWeb.IncentivesControllerTest do
  use CadetWeb.ConnCase

  import Cadet.{Factory, TestEntityHelper}

  alias Cadet.Repo
  alias CadetWeb.IncentivesController
  alias Cadet.Incentives.{Goals, GoalProgress}
  alias Ecto.UUID

  test "swagger" do
    assert is_map(IncentivesController.swagger_definitions())
    assert is_map(IncentivesController.swagger_path_index_achievements(nil))
    assert is_map(IncentivesController.swagger_path_index_goals(nil))
    assert is_map(IncentivesController.swagger_path_update_progress(nil))
  end

  describe "GET v2/coures/:course_id/achievements" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn} do
      course = conn.assigns.test_cr.course
      insert(:achievement, Map.merge(achievement_literal(0), %{course: course}))

      resp = conn |> get(build_url_achievements(course.id)) |> json_response(200)

      assert [achievement_json_literal(0)] = resp
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)
      conn |> get(build_url_achievements(course.id)) |> response(401)
    end
  end

  describe "GET v2/coures/:course_id/self/goals" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn} do
      course = conn.assigns.test_cr.course
      insert(:goal, Map.merge(goal_literal(0), %{course: course}))

      resp = conn |> get(build_url_goals(course.id)) |> json_response(200)

      assert [goal_json_literal(0)] = resp
    end

    @tag authenticate: :student
    test "includes user's progress", %{conn: conn} do
      course_reg = conn.assigns.test_cr
      goal = insert(:goal, Map.merge(goal_literal(0), %{course: course_reg.course}))

      {:ok, progress} =
        %GoalProgress{
          goal_uuid: goal.uuid,
          course_reg_id: course_reg.id,
          count: 123,
          completed: true
        }
        |> Repo.insert()

      [resp_goal] = conn |> get(build_url_goals(course_reg.course_id)) |> json_response(200)

      assert goal_json_literal(0) = resp_goal
      assert resp_goal["count"] == progress.count
      assert resp_goal["completed"] == progress.completed
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)
      conn |> get(build_url_goals(course.id)) |> response(401)
    end
  end

  describe "POST v2/coures/:course_id/self/goals/:uuid/progress" do
    @tag authenticate: :student
    test "succeeds if authenticated", %{conn: conn} do
      course_reg = conn.assigns.test_cr
      uuid = UUID.generate()

      goal =
        insert(
          :goal,
          Map.merge(goal_literal(5), %{
            course: course_reg.course,
            course_id: course_reg.course_id,
            uuid: uuid
          })
        )

      conn
      |> post(build_url_goals(course_reg.course_id, goal.uuid), %{
        "progress" => %{
          count: 100,
          completed: false,
          course_reg_id: course_reg.id,
          uuid: goal.uuid
        }
      })
      |> response(204)

      retrieved_goal = Goals.get_with_progress(course_reg)
      assert [%{progress: [%{count: 100, completed: false}]}] = retrieved_goal
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)
      uuid = UUID.generate()

      goal =
        insert(
          :goal,
          Map.merge(goal_literal(5), %{course: course, course_id: course.id, uuid: uuid})
        )

      conn
      |> post(build_url_goals(course.id, goal.uuid), %{
        "progress" => %{count: 100, completed: false, course_reg_id: 1, uuid: goal.uuid}
      })
      |> response(401)
    end
  end

  defp build_url_achievements(course_id),
    do: "/v2/courses/#{course_id}/achievements"

  defp build_url_goals(course_id),
    do: "/v2/courses/#{course_id}/self/goals"

  defp build_url_goals(course_id, uuid),
    do: "/v2/courses/#{course_id}/self/goals/#{uuid}/progress"
end
