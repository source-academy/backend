defmodule Cadet.AchievementsTest do
  use Cadet.DataCase

  alias Cadet.Achievements

  alias Cadet.Achievements.{
    Achievement,
    AchievementAbility,
    AchievementGoal
  }

  test "create achievements" do
    user = insert(:user, %{name: "admin", role: :admin})

    for ability <- AchievementAbility.__enum_map__() do
      title_string = Atom.to_string(ability)

      {_res, achievement} =
        Achievements.insert_or_update_achievement(
          user,
          %{
            inferencer_id: 0,
            title: title_string,
            ability: ability,
            is_task: false,
            position: 0
          }
        )

      assert %{title: ^title_string, ability: ^ability} = achievement
    end
  end

  test "get achievements from user" do
    user = insert(:user)
    achievements = Achievements.all_achievements(user)

    assert [] = achievements
  end

  test "get all achievement fields from user" do
    user = insert(:user, %{name: "admin", role: :admin})

    achievement =
      insert(:achievement, %{
        inferencer_id: 0,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0,
        background_image_url: "",
        modal_image_url: "",
        description: "",
        completion_text: ""
      })

    prereq =
      insert(:achievement, %{
        inferencer_id: 1,
        title: "Tests",
        ability: :Core,
        is_task: false,
        position: 0
      })

    insert(:achievement_prerequisite, %{
      inferencer_id: prereq.inferencer_id,
      achievement_id: achievement.id
    })

    insert(:achievement_goal, %{
      goal_id: 1,
      goal_text: "Score earned from Curve Introduction mission",
      goal_progress: 70,
      goal_target: 200,
      achievement_id: achievement.id,
      user_id: user.id
    })

    achievements = Achievements.all_achievements(user)

    assert [
             %{
               ability: :Core,
               background_image_url: "",
               completion_text: "",
               description: "",
               goals: [
                 %{
                   goal_id: 1,
                   goal_progress: 70,
                   goal_target: 200,
                   goal_text: "Score earned from Curve Introduction mission"
                 }
               ],
               id: :id,
               inferencer_id: 0,
               is_task: false,
               modal_image_url: "",
               position: 0,
               prerequisite_ids: [1],
               title: "Test"
             }
           ] = achievements
  end

  test "update achievements" do
    user = insert(:user, %{name: "admin", role: :admin})

    new_title = "New String"

    insert(:achievement, %{
      inferencer_id: 69,
      title: "Test",
      ability: :Core,
      is_task: false,
      position: 0
    })

    {_res, achievement} =
      Achievements.insert_or_update_achievement(
        user,
        %{
          inferencer_id: 69,
          title: "New String",
          ability: :Core,
          is_task: false,
          position: 0
        }
      )

    assert %{title: ^new_title} = achievement
  end

  test "update prerequisites" do
    user = insert(:user, %{name: "admin", role: :admin})

    achievement =
      insert(:achievement, %{
        inferencer_id: 69,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0
      })

    insert(:achievement, %{
      inferencer_id: 70,
      title: "Test",
      ability: :Core,
      is_task: false,
      position: 0
    })

    insert(:achievement, %{
      inferencer_id: 71,
      title: "Test",
      ability: :Core,
      is_task: false,
      position: 0
    })

    result =
      Achievements.update_prerequisites(user, %{
        inferencer_id: achievement.inferencer_id,
        prerequisites: [70, 71]
      })

    assert result == :ok
  end

  test "delete achievement" do
    user = insert(:user, %{name: "admin", role: :admin})

    achievement =
      insert(:achievement, %{
        inferencer_id: 69,
        title: "Test",
        ability: :Core,
        is_task: false,
        position: 0
      })

    Achievements.delete_achievement(user, achievement.inferencer_id)
    assert Repo.get(Achievement, achievement.id) == nil
  end

  test "update goals" do
    user = insert(:user, %{name: "admin", role: :admin})

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

    result =
      Achievements.update_goals(
        user,
        %{
          inferencer_id: achievement.inferencer_id,
          goals: []
        }
      )

    assert result == :ok

    student = insert(:user, %{name: "student", role: :student})

    result = Achievements.add_new_user_goals(user)

    assert result == :ok
  end

  test "delete goal" do
    user = insert(:user, %{name: "admin", role: :admin})

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

    Achievements.delete_goal(user, goal.goal_id, achievement.inferencer_id)
    assert Repo.get(AchievementGoal, goal.id) == nil
  end
end
