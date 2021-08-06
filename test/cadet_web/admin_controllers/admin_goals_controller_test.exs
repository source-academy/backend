defmodule CadetWeb.AdminGoalsControllerTest do
  use CadetWeb.ConnCase

  import Cadet.TestEntityHelper

  alias Cadet.Repo
  alias Cadet.Incentives.{Goal, Goals, GoalProgress}
  alias CadetWeb.AdminGoalsController
  alias Ecto.UUID

  test "swagger" do
    assert is_map(AdminGoalsController.swagger_path_index(nil))
    assert is_map(AdminGoalsController.swagger_path_index_goals_with_progress(nil))
    assert is_map(AdminGoalsController.swagger_path_update(nil))
    assert is_map(AdminGoalsController.swagger_path_bulk_update(nil))
    assert is_map(AdminGoalsController.swagger_path_delete(nil))
    assert is_map(AdminGoalsController.swagger_path_update_progress(nil))
  end

  describe "GET v2/courses/:course_id/admin/goals" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      course_id = conn.assigns.course_id

      {:ok, goal} =
        %Goal{course_id: course_id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      [resp_goal] =
        conn
        |> get(build_path(course_id))
        |> json_response(200)

      assert goal_json_literal(5) = resp_goal
      assert resp_goal["uuid"] == goal.uuid
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn
      |> get(build_path(course_id))
      |> response(403)
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)

      conn
      |> get(build_path(course.id))
      |> response(401)
    end
  end

  describe "GET v2/courses/:course_id/admin/users/:course_reg_id/goals" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      course = conn.assigns.test_cr.course

      {:ok, g} =
        %Goal{course_id: course.id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      course_reg = insert(:course_registration, %{course: course, role: :student})

      {:ok, p} =
        %GoalProgress{
          goal_uuid: g.uuid,
          course_reg_id: course_reg.id,
          count: 123,
          completed: true
        }
        |> Repo.insert()

      [resp_goal] =
        conn
        |> get(build_user_goals_path(course.id, course_reg.id))
        |> json_response(200)

      assert goal_json_literal(5) = resp_goal
      assert resp_goal["uuid"] == g.uuid
      assert resp_goal["count"] == p.count
      assert resp_goal["completed"] == p.completed
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn
      |> get(build_path(course_id))
      |> response(403)
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)

      conn
      |> get(build_path(course.id))
      |> response(401)
    end
  end

  describe "PUT v2/courses/:course_id/admin/goals/:uuid" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      course_id = conn.assigns.course_id
      uuid = UUID.generate()

      conn
      |> put(build_path(course_id, uuid), %{"goal" => goal_json_literal(0)})
      |> response(204)

      ach = Repo.get(Goal, uuid)

      assert goal_literal(0) = ach
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      course_id = conn.assigns.course_id
      uuid = UUID.generate()

      conn
      |> put(build_path(course_id, uuid), %{"goal" => goal_json_literal(0)})
      |> response(403)

      assert Goal |> Repo.get(uuid) |> is_nil()
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)
      uuid = UUID.generate()

      conn
      |> put(build_path(course.id, uuid), %{"goal" => goal_json_literal(0)})
      |> response(401)

      assert Goal |> Repo.get(uuid) |> is_nil()
    end
  end

  describe "PUT v2/courses/:course_id/admin/goals" do
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
      course_id = conn.assigns.course_id

      conn
      |> put(build_path(course_id), %{
        "goals" => goals
      })
      |> response(204)

      assert goal_literal(1) = Repo.get(Goal, a1["uuid"])
      assert goal_literal(2) = Repo.get(Goal, a2["uuid"])
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn, goals: goals = [a1, a2]} do
      course_id = conn.assigns.course_id

      conn
      |> put(build_path(course_id), %{
        "goals" => goals
      })
      |> response(403)

      assert Goal |> Repo.get(a1["uuid"]) |> is_nil()
      assert Goal |> Repo.get(a2["uuid"]) |> is_nil()
    end

    test "401 if unauthenticated", %{conn: conn, goals: goals = [a1, a2]} do
      course = insert(:course)

      conn
      |> put(build_path(course.id), %{
        "goals" => goals
      })
      |> response(401)

      assert Goal |> Repo.get(a1["uuid"]) |> is_nil()
      assert Goal |> Repo.get(a2["uuid"]) |> is_nil()
    end
  end

  describe "DELETE v2/courses/:course_id/admin/goals/:uuid" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      course_id = conn.assigns.course_id

      {:ok, a} =
        %Goal{course_id: course_id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      conn
      |> delete(build_path(course_id, a.uuid))
      |> response(204)

      assert Goal |> Repo.get(a.uuid) |> is_nil()
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      course_id = conn.assigns.course_id

      {:ok, a} =
        %Goal{course_id: course_id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      conn
      |> delete(build_path(course_id, a.uuid))
      |> response(403)

      assert goal_literal(5) = Repo.get(Goal, a.uuid)
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)

      {:ok, a} =
        %Goal{course_id: course.id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      conn
      |> delete(build_path(course.id, a.uuid))
      |> response(401)

      assert goal_literal(5) = Repo.get(Goal, a.uuid)
    end
  end

  describe "POST v2/courses/:course_id/goals/:uuid/progress/:course_reg_id" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      course = conn.assigns.test_cr.course

      {:ok, g} =
        %Goal{course_id: course.id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      course_reg = insert(:course_registration, %{course: course, role: :student})

      conn
      |> post(build_path(course.id, g.uuid, course_reg.id), %{
        "progress" => %{count: 100, completed: false, course_reg_id: course_reg.id, uuid: g.uuid}
      })
      |> response(204)

      retrieved_goal = Goals.get_with_progress(course_reg)
      assert [%{progress: [%{count: 100, completed: false}]}] = retrieved_goal
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      course = conn.assigns.test_cr.course

      {:ok, g} =
        %Goal{course_id: course.id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      course_reg = insert(:course_registration, %{course: course, role: :student})

      conn
      |> post(build_path(course.id, g.uuid, course_reg.id), %{
        "progress" => %{count: 100, completed: false, course_reg_id: course_reg.id, uuid: g.uuid}
      })
      |> response(403)
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)

      {:ok, g} =
        %Goal{course_id: course.id, uuid: UUID.generate()}
        |> Map.merge(goal_literal(5))
        |> Repo.insert()

      course_reg = insert(:course_registration, %{course: course, role: :student})

      conn
      |> post(build_path(course.id, g.uuid, course_reg.id), %{
        "progress" => %{count: 100, completed: false, course_reg_id: course_reg.id, uuid: g.uuid}
      })
      |> response(401)
    end
  end

  defp build_path(course_id, uuid \\ nil)

  defp build_path(course_id, nil) do
    "/v2/courses/#{course_id}/admin/goals"
  end

  defp build_path(course_id, uuid) do
    "/v2/courses/#{course_id}/admin/goals/#{uuid}"
  end

  defp build_path(course_id, uuid, course_reg_id) do
    "/v2/courses/#{course_id}/admin/users/#{course_reg_id}/goals/#{uuid}/progress/"
  end

  defp build_user_goals_path(course_id, course_reg_id) do
    "/v2/courses/#{course_id}/admin/users/#{course_reg_id}/goals"
  end
end
