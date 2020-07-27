defmodule CadetWeb.AchievementsControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias Cadet.Repo
  alias CadetWeb.AchievementsController
  alias Cadet.Achievements.{Achievement, AchievementGoal, AchievementProgress}
  alias Ecto.Query

  require Query

  setup do
    achievement =
      insert(:achievement, %{
        id: 69,
        title: "Test",
        ability: "Core",
        is_task: false,
        position: 0
      })

    goal =
      insert(:achievement_goal, %{
        order: 1,
        text: "Score earned from Curve Introduction mission",
        target: 200,
        achievement_id: achievement.id
      })

    %{achievement: achievement, goal: goal}
  end

  test "swagger" do
    assert is_map(AchievementsController.swagger_definitions())
    assert is_map(AchievementsController.swagger_path_index(nil))
    assert is_map(AchievementsController.swagger_path_update(nil))
    assert is_map(AchievementsController.swagger_path_delete(nil))
    assert is_map(AchievementsController.swagger_path_delete_goal(nil))
  end

  describe "GET /achievements" do
    @tag authenticate: :staff
    test "succeeds for authenticated user", %{conn: conn, goal: goal} do
      %AchievementProgress{user_id: conn.assigns.current_user.id, goal_id: goal.id, progress: 70}
      |> Repo.insert()

      resp_achievement =
        conn
        |> get("/v1/achievements")
        |> json_response(200)
        |> Enum.at(0)
        |> Map.drop(["deadline", "release"])
        |> Map.update!("view", &Map.drop(&1, ["completionText", "description"]))

      assert %{
               "ability" => "Core",
               "cardTileUrl" => nil,
               "goals" => [
                 %{
                   "goalId" => 1,
                   "goalProgress" => 70,
                   "goalTarget" => 200,
                   "goalText" => "Score earned from Curve Introduction mission"
                 }
               ],
               "id" => 69,
               "isTask" => false,
               "view" => %{
                 "canvasUrl" =>
                   "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/canvas/annotated-canvas.png"
               },
               "position" => 0,
               "prerequisiteIds" => [],
               "title" => "Test"
             } == resp_achievement
    end
  end

  describe "DELETE /achievements/:id" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn, achievement: achievement} do
      assert conn |> delete(build_delete_achievement_url(achievement.id)) |> response(204)
      assert is_nil(Repo.get(Achievement, achievement.id))
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn, achievement: achievement} do
      assert conn |> delete(build_delete_achievement_url(achievement.id)) |> response(403) =~
               "User is not permitted to edit achievements"
    end
  end

  describe "DELETE /achievements/:id/goals/:order" do
    @tag authenticate: :staff
    test "succeeds for staff", %{conn: conn, achievement: achievement, goal: goal} do
      assert conn |> delete(build_delete_goal_url(achievement.id, goal.order)) |> response(204)
      assert is_nil(Repo.get(AchievementGoal, goal.id))
    end

    @tag authenticate: :student
    test "403 for student", %{conn: conn, achievement: achievement, goal: goal} do
      assert conn |> delete(build_delete_goal_url(achievement.id, goal.order)) |> response(403) =~
               "User is not permitted to edit achievements"
    end
  end

  describe "POST /achievements/:id" do
    @tag authenticate: :staff
    test "succeeds for staff", %{
      conn: conn,
      achievement: achievement
    } do
      release = DateTime.truncate(DateTime.utc_now(), :second)
      deadline = DateTime.add(release, 3600, :second)

      new_achievement = %{
        "id" => achievement.id,
        "title" => Faker.Food.En.description(),
        "ability" => "Core",
        "isTask" => false,
        "position" => 124_345,
        "cardTileUrl" => Faker.UUID.v4(),
        "deadline" => format_datetime(deadline),
        "release" => format_datetime(release),
        "goals" => [],
        "prerequisiteIds" => [],
        "view" => %{
          "canvasUrl" => Faker.UUID.v4(),
          "description" => Faker.Food.En.description(),
          "completionText" => Faker.App.name()
        }
      }

      conn = post(conn, "/v1/achievements/#{achievement.id}", %{achievement: new_achievement})

      assert "Success" == response(conn, 200)

      inserted_achievement = Repo.get(Achievement, achievement.id)

      assert new_achievement["title"] == inserted_achievement.title
      assert new_achievement["ability"] == inserted_achievement.ability
      assert new_achievement["isTask"] == inserted_achievement.is_task
      assert new_achievement["position"] == inserted_achievement.position
      assert new_achievement["cardTileUrl"] == inserted_achievement.card_tile_url
      assert deadline == inserted_achievement.close_at
      assert release == inserted_achievement.open_at
      assert new_achievement["view"]["canvasUrl"] == inserted_achievement.canvas_url
      assert new_achievement["view"]["description"] == inserted_achievement.description
      assert new_achievement["view"]["completionText"] == inserted_achievement.completion_text
    end

    @tag authenticate: :staff
    test "with goals", %{
      conn: conn,
      achievement: achievement,
      goal: goal
    } do
      achievement_title = "New Title"
      goal_text = "New Text"
      goal_target = 123_456

      new_achievement = %{
        "id" => achievement.id,
        "title" => achievement_title,
        "goals" => [
          %{
            "goalId" => goal.order,
            "goalText" => goal_text,
            "goalTarget" => goal_target
          }
        ]
      }

      conn = post(conn, "/v1/achievements/#{achievement.id}", %{achievement: new_achievement})

      assert "Success" == response(conn, 200)

      new_achievement =
        Achievement
        |> Query.preload([:goals])
        |> Repo.get(achievement.id)

      assert %{title: ^achievement_title, goals: [%{text: ^goal_text, target: ^goal_target}]} =
               new_achievement
    end

    @tag authenticate: :staff
    test "with prerequisites", %{
      conn: conn,
      achievement: achievement
    } do
      prereq_1 = insert(:achievement, id: Faker.random_between(100, 200))
      prereq_2 = insert(:achievement, id: Faker.random_between(300, 400))
      prereq_ids = [prereq_1.id, prereq_2.id]

      new_achievement = %{
        "id" => achievement.id,
        "prerequisiteIds" => prereq_ids
      }

      conn = post(conn, "/v1/achievements/#{achievement.id}", %{achievement: new_achievement})

      assert "Success" == response(conn, 200)

      new_achievement =
        Achievement
        |> Query.preload([:prerequisites])
        |> Repo.get(achievement.id)

      assert ^prereq_ids =
               new_achievement.prerequisites
               |> Enum.map(fn %{prerequisite_id: id} -> id end)
               |> Enum.sort()
    end

    @tag authenticate: :student
    test "403 for student", %{
      conn: conn,
      achievement: achievement
    } do
      new_achievement = %{
        "id" => achievement.id,
        "title" => "New Title"
      }

      conn = post(conn, "/v1/achievements/#{achievement.id}", %{achievement: new_achievement})

      assert response(conn, 403) =~
               "User is not permitted to edit achievements"
    end
  end

  defp build_delete_achievement_url(id), do: "/v1/achievements/#{id}"

  defp build_delete_goal_url(id, order),
    do: "/v1/achievements/#{id}/goals/#{order}"
end
