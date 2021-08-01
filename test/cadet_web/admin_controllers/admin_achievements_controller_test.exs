defmodule CadetWeb.AdminAchievementsControllerTest do
  use CadetWeb.ConnCase

  import Cadet.TestEntityHelper

  alias Cadet.Repo
  alias Cadet.Incentives.Achievement
  alias CadetWeb.AdminAchievementsController
  alias Ecto.UUID

  test "swagger" do
    assert is_map(AdminAchievementsController.swagger_path_update(nil))
    assert is_map(AdminAchievementsController.swagger_path_bulk_update(nil))
    assert is_map(AdminAchievementsController.swagger_path_delete(nil))
  end

  describe "PUT v2/courses/:course_id/admin/achievements/:uuid" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      course_id = conn.assigns.course_id
      uuid = UUID.generate()

      conn
      |> put(build_path(course_id, uuid), %{"achievement" => achievement_json_literal(0)})
      |> response(204)

      ach = Repo.get(Achievement, uuid)

      assert achievement_literal(0) = ach
    end

    @tag authenticate: :staff
    test "succeeds without view", %{conn: conn} do
      course_id = conn.assigns.course_id
      uuid = UUID.generate()

      conn
      |> put(build_path(course_id, uuid), %{
        "achievement" => Map.drop(achievement_json_literal(0), ["view"])
      })
      |> response(204)

      ach = Repo.get(Achievement, uuid)

      assert achievement_literal(0) =
               Map.merge(
                 ach,
                 Map.take(achievement_literal(0), [:canvas_url, :completion_text, :description])
               )
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      course = insert(:course)
      uuid = UUID.generate()

      conn
      |> put(build_path(course.id, uuid), %{"achievement" => achievement_json_literal(0)})
      |> response(403)

      assert Achievement |> Repo.get(uuid) |> is_nil()
    end

    test "401 if unauthenticated", %{conn: conn} do
      uuid = UUID.generate()

      conn
      |> put(build_path(uuid), %{"achievement" => achievement_json_literal(0)})
      |> response(401)

      assert Achievement |> Repo.get(uuid) |> is_nil()
    end
  end

  describe "PUT v2/courses/:course_id/admin/achievements" do
    setup do
      %{
        achievements: [
          Map.merge(achievement_json_literal(1), %{"uuid" => UUID.generate()}),
          Map.merge(achievement_json_literal(2), %{"uuid" => UUID.generate()})
        ]
      }
    end

    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn, achievements: achs = [a1, a2]} do
      course_id = conn.assigns.course_id

      conn
      |> put(build_path(course_id), %{
        "achievements" => achs
      })
      |> response(204)

      assert achievement_literal(1) = Repo.get(Achievement, a1["uuid"])
      assert achievement_literal(2) = Repo.get(Achievement, a2["uuid"])
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn, achievements: achs = [a1, a2]} do
      course_id = conn.assigns.course_id

      conn
      |> put(build_path(course_id), %{
        "achievements" => achs
      })
      |> response(403)

      assert Achievement |> Repo.get(a1["uuid"]) |> is_nil()
      assert Achievement |> Repo.get(a2["uuid"]) |> is_nil()
    end

    test "401 if unauthenticated", %{conn: conn, achievements: achs = [a1, a2]} do
      course = insert(:course)

      conn
      |> put(build_path(course.id), %{
        "achievements" => achs
      })
      |> response(401)

      assert Achievement |> Repo.get(a1["uuid"]) |> is_nil()
      assert Achievement |> Repo.get(a2["uuid"]) |> is_nil()
    end
  end

  describe "DELETE v2/courses/:course_id/admin/achievements/:uuid" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn} do
      course_id = conn.assigns.course_id

      {:ok, a} =
        %Achievement{course_id: course_id, uuid: UUID.generate()}
        |> Map.merge(achievement_literal(5))
        |> Repo.insert()

      conn
      |> delete(build_path(course_id, a.uuid))
      |> response(204)

      assert Achievement |> Repo.get(a.uuid) |> is_nil()
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn} do
      course_id = conn.assigns.course_id

      {:ok, a} =
        %Achievement{course_id: course_id, uuid: UUID.generate()}
        |> Map.merge(achievement_literal(5))
        |> Repo.insert()

      conn
      |> delete(build_path(course_id, a.uuid))
      |> response(403)

      assert achievement_literal(5) = Repo.get(Achievement, a.uuid)
    end

    test "401 if unauthenticated", %{conn: conn} do
      course = insert(:course)

      {:ok, a} =
        %Achievement{course_id: course.id, uuid: UUID.generate()}
        |> Map.merge(achievement_literal(5))
        |> Repo.insert()

      conn
      |> delete(build_path(course.id, a.uuid))
      |> response(401)

      assert achievement_literal(5) = Repo.get(Achievement, a.uuid)
    end
  end

  defp build_path(course_id, uuid \\ nil)

  defp build_path(course_id, nil) do
    "/v2/courses/#{course_id}/admin/achievements"
  end

  defp build_path(course_id, uuid) do
    "/v2/courses/#{course_id}/admin/achievements/#{uuid}"
  end
end
