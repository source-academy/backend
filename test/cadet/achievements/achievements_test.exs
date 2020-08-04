defmodule Cadet.AchievementsTest do
  use Cadet.DataCase

  alias Cadet.Accounts.User

  alias Cadet.Achievements

  alias Cadet.Achievements.{
    Achievement,
    AchievementGoal,
    AchievementProgress
  }

  test "create achievements" do
    for {ability, id} <- Enum.with_index(Achievement.valid_abilities()) do
      {:ok, _} =
        Achievements.insert_or_update_achievement(
          %User{role: :admin},
          %{
            id: id,
            title: ability,
            ability: ability,
            is_task: false,
            position: 0
          }
        )

      assert %{title: ^ability, ability: ^ability} = Repo.get(Achievement, id)
    end
  end

  test "create achievement with goals" do
    achievement_title = "Achievement"
    achievement_ability = "Core"
    goal_text = "Goal"
    goal_target = 100
    goal_order = 0

    {:ok, _} =
      Achievements.insert_or_update_achievement(
        %User{role: :admin},
        %{
          id: 0,
          title: achievement_title,
          ability: achievement_ability,
          is_task: false,
          position: 0,
          goals: [
            %{
              order: goal_order,
              target: goal_target,
              text: goal_text
            }
          ]
        }
      )

    assert %{title: ^achievement_title, ability: ^achievement_ability} = Repo.one(Achievement)

    assert %{order: ^goal_order, target: ^goal_target, text: ^goal_text} =
             Repo.one(AchievementGoal)
  end

  test "create achievement with goal without order" do
    {:error, {:bad_request, _}} =
      Achievements.insert_or_update_achievement(
        %User{role: :admin},
        %{
          id: 0,
          title: "Achievement",
          ability: "Core",
          is_task: false,
          position: 0,
          goals: [
            %{
              target: 100,
              text: "Goal"
            }
          ]
        }
      )
  end

  test "create achievement with prerequisites as id" do
    insert(:achievement, id: 50)
    insert(:achievement, id: 51)
    prerequisite_ids = [50, 51]

    {:ok, _} =
      Achievements.insert_or_update_achievement(
        %User{role: :admin},
        %{
          id: 0,
          title: "Achievement",
          ability: "Core",
          is_task: false,
          position: 0,
          prerequisites: prerequisite_ids
        }
      )

    assert prerequisite_ids == get_prerequisites(0)
  end

  test "get user achievements when no achievements" do
    user = insert(:user)
    achievements = Achievements.get_user_achievements(user)

    assert [] == achievements
  end

  test "get user achievements" do
    user = insert(:user, %{name: "admin", role: :admin})

    achievement =
      insert(:achievement, %{
        id: 0,
        title: "Test",
        ability: "Core",
        is_task: false,
        position: 0,
        card_tile_url: "",
        canvas_url: "",
        description: "",
        completion_text: ""
      })

    prereq =
      insert(:achievement, %{
        id: 1,
        title: "Tests",
        ability: "Core",
        is_task: false,
        position: 0
      })

    insert(:achievement_prerequisite, %{
      prerequisite_id: prereq.id,
      achievement_id: achievement.id
    })

    goal =
      insert(:achievement_goal, %{
        order: 1,
        text: "Score earned from Curve Introduction mission",
        target: 200,
        achievement_id: achievement.id
      })

    Repo.insert(%AchievementProgress{
      goal_id: goal.id,
      user_id: user.id,
      progress: 70
    })

    achievements = Achievements.get_user_achievements(user)

    assert [
             %{
               ability: "Core",
               card_tile_url: "",
               completion_text: "",
               description: "",
               goals: [
                 %{
                   order: 1,
                   progress: [%{progress: 70}],
                   target: 200,
                   text: "Score earned from Curve Introduction mission"
                 }
               ],
               id: 0,
               is_task: false,
               canvas_url: "",
               position: 0,
               prerequisites: [%{prerequisite_id: 1}],
               title: "Test"
             }
             | _
           ] = achievements
  end

  test "update achievements" do
    user = insert(:user, %{name: "admin", role: :admin})
    id = 69
    new_title = "New String"

    insert(:achievement, %{
      id: id,
      title: "Test",
      ability: "Core",
      is_task: false,
      position: 0
    })

    assert {:ok, _} =
             Achievements.insert_or_update_achievement(
               user,
               %{
                 id: id,
                 title: "New String",
                 ability: "Core",
                 is_task: false,
                 position: 0
               }
             )

    assert %{title: ^new_title} = Repo.get(Achievement, id)
  end

  test "update prerequisites" do
    user = insert(:user, %{name: "admin", role: :admin})

    achievement =
      insert(:achievement, %{
        id: 69,
        title: "Test",
        ability: "Core",
        is_task: false,
        position: 0
      })

    insert(:achievement, %{
      id: 70,
      title: "Test",
      ability: "Core",
      is_task: false,
      position: 0
    })

    insert(:achievement, %{
      id: 71,
      title: "Test",
      ability: "Core",
      is_task: false,
      position: 0
    })

    test_change_prerequisite(user, achievement.id, [])
    test_change_prerequisite(user, achievement.id, [70, 71])
    test_change_prerequisite(user, achievement.id, [70])
    test_change_prerequisite(user, achievement.id, [71])
    test_change_prerequisite(user, achievement.id, [])
  end

  defp test_change_prerequisite(user, achievement_id, prerequisite_ids) do
    assert {:ok, _} =
             Achievements.insert_or_update_achievement(user, %{
               id: achievement_id,
               prerequisites: make_prerequisites(achievement_id, prerequisite_ids)
             })

    assert prerequisite_ids == get_prerequisites(achievement_id)
  end

  defp get_prerequisites(achievement_id) do
    Achievement
    |> preload([:prerequisites])
    |> Repo.get(achievement_id)
    |> Map.fetch!(:prerequisites)
    |> Enum.map(& &1.prerequisite_id)
    |> Enum.sort()
  end

  defp make_prerequisites(achievement_id, prerequisite_ids) do
    Enum.map(prerequisite_ids, &%{prerequisite_id: &1, achievement_id: achievement_id})
  end

  test "delete achievement" do
    user = insert(:user, %{name: "admin", role: :admin})

    achievement =
      insert(:achievement, %{
        id: 69,
        title: "Test",
        ability: "Core",
        is_task: false,
        position: 0
      })

    Achievements.delete_achievement(user, achievement.id)
    assert Achievement |> Repo.get(achievement.id) |> is_nil()
  end

  test "update goals" do
    user = insert(:user, %{name: "admin", role: :admin})

    achievement =
      insert(:achievement, %{
        id: 69,
        title: "Test",
        ability: "Core",
        is_task: false,
        position: 0
      })

    insert(:achievement_goal, %{
      order: 1,
      text: "Score earned from Curve Introduction mission",
      target: 200,
      achievement_id: achievement.id
    })

    new_text = "Hello World"

    assert {:ok, _} =
             Achievements.insert_or_update_achievement(
               user,
               %{
                 id: achievement.id,
                 goals: [
                   %{
                     order: 1,
                     text: new_text,
                     target: 1
                   }
                 ]
               }
             )

    assert %{text: ^new_text} = Repo.one(AchievementGoal)

    new_text_2 = "Another goal"

    assert {:ok, _} =
             Achievements.insert_or_update_achievement(
               user,
               %{
                 id: achievement.id,
                 goals: [
                   %{
                     order: 2,
                     text: new_text_2,
                     target: 1
                   }
                 ]
               }
             )

    assert [%{text: ^new_text}, %{text: ^new_text_2}] =
             AchievementGoal |> order_by(:order) |> Repo.all()
  end

  test "update goal with missing order" do
    achievement =
      insert(:achievement, %{
        id: 69,
        title: "Test",
        ability: "Core",
        is_task: false,
        position: 0
      })

    insert(:achievement_goal, %{
      order: 1,
      text: "Score earned from Curve Introduction mission",
      target: 200,
      achievement_id: achievement.id
    })

    assert {:error, {:bad_request, _}} =
             Achievements.insert_or_update_achievement(
               %User{role: :admin},
               %{
                 id: achievement.id,
                 goals: [
                   %{
                     text: "Hello World",
                     target: 1
                   }
                 ]
               }
             )
  end

  test "delete goal" do
    user = insert(:user, %{name: "admin", role: :admin})

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

    Achievements.delete_goal(user, achievement.id, goal.order)
    assert AchievementGoal |> Repo.get(goal.id) |> is_nil()
  end
end
