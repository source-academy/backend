defmodule CadetWeb.AchievementsControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias Cadet.Repo
  alias CadetWeb.AchievementsController
  alias Cadet.Achievements.{AchievementGoal, AchievementAbility}

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
end
