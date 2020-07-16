defmodule CadetWeb.AchievementsControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias Cadet.Repo
  alias CadetWeb.AchievementsController
  alias Cadet.Achievements.{Achievement, AchievementGoal}

  test "swagger" do
    assert is_map(AchievementsController.swagger_definitions())
    assert is_map(AchievementsController.swagger_path_index(nil))
  end

  @tag authenticate: :staff
  test "get achievements", %{conn: conn} do
    user = conn.assigns.current_user

    achievement =
      insert(:achievement, %{
        inferencer_id: 69,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0
      })

    insert(:achievement_goal, %{
      goal_id: 1,
      goal_text: "Score earned from Curve Introduction mission",
      goal_progress: 70,
      goal_target: 200,
      achievement_id: achievement.id,
      user_id: user.id
    })

    resp_achievement =
      conn
      |> get("/v1/achievements")
      |> json_response(200)
      |> Enum.at(0)
      |> Map.delete("openAt")
      |> Map.delete("closeAt")
      |> Map.delete("description")
      |> Map.delete("completionText")

    assert resp_achievement == %{
             "ability" => "Core",
             "backgroundImageUrl" => nil,
             "goals" => [
               %{
                 "goalId" => 1,
                 "goalProgress" => 70,
                 "goalTarget" => 200,
                 "goalText" => "Score earned from Curve Introduction mission"
               }
             ],
             "id" => "id",
             "inferencer_id" => 69,
             "isTask" => false,
             "modalImageUrl" =>
               "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/canvas/annotated-canvas.png",
             "position" => 0,
             "prerequisiteIds" => [],
             "title" => "Test"
           }
  end

  @tag authenticate: :staff
  test "staff can delete achievement", %{conn: conn} do
    achievement =
      insert(:achievement, %{
        inferencer_id: 69,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0
      })

    conn = delete(conn, build_delete_achievement_url(achievement.inferencer_id))
    assert response(conn, 200) == "OK"
    assert Repo.get(Achievement, achievement.id) == nil
  end

  @tag authenticate: :student
  test "student cannot delete achievement", %{conn: conn} do
    achievement =
      insert(:achievement, %{
        inferencer_id: 69,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0
      })

    conn = delete(conn, build_delete_achievement_url(achievement.inferencer_id))
    assert response(conn, 403) =~ "User is not permitted to edit achievements"
  end

  @tag authenticate: :staff
  test "staff can delete goal", %{conn: conn} do
    user = conn.assigns.current_user

    achievement =
      insert(:achievement, %{
        inferencer_id: 69,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0
      })

    goal =
      insert(:achievement_goal, %{
        goal_id: 1,
        goal_text: "Score earned from Curve Introduction mission",
        goal_progress: 70,
        goal_target: 200,
        achievement_id: achievement.id,
        user_id: user.id
      })

    conn = delete(conn, build_delete_goal_url(achievement.inferencer_id, goal.goal_id))
    assert response(conn, 200) == "OK"
    assert Repo.get(AchievementGoal, goal.id) == nil
  end

  @tag authenticate: :staff
  test "staff is able to edit single achievement", %{conn: conn} do
    achievement =
      insert(:achievement, %{
        inferencer_id: 69,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0
      })

    new_achievement = %{
      "id" => 69,
      "title" => "New Title",
      "ability" => "Core",
      "isTask" => false,
      "position" => 0,
      "backgroundImageUrl" => nil,
      "deadline" =>
        DateTime.to_string(
          DateTime.truncate(DateTime.add(DateTime.utc_now(), 3600, :second), :second)
        ),
      "release" => DateTime.to_string(DateTime.truncate(DateTime.utc_now(), :second)),
      "goals" => [],
      "prerequisiteIds" => [],
      "modal" => %{
        "modalImageUrl" => nil,
        "description" => "",
        "completionText" => ""
      }
    }

    conn =
      post(conn, "v1/achievements/#{achievement.inferencer_id}", %{achievement: new_achievement})

    assert response(conn, 200) == "OK"
    assert Repo.get(Achievement, achievement.id).title == "New Title"
  end

  defp build_delete_achievement_url(inferencer_id), do: "/v1/achievements/#{inferencer_id}"

  defp build_delete_goal_url(inferencer_id, goal_id),
    do: "/v1/achievements/#{inferencer_id}/goals/#{goal_id}"
end
