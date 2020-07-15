defmodule Cadet.AchievementsTest do
  use Cadet.DataCase

  alias Cadet.Achievements
  alias Cadet.Achievements.{AchievementAbility}

  test "create achievements" do
    user = insert(:user, %{name: "admin", role: :admin})

    for ability <- AchievementAbility.__enum_map__() do
      title_string = Atom.to_string(ability)

      {_res, achievement} =
        Achievements.insert_or_update_achievement(user, 
        %{
          inferencer_id: 0,
          title: title_string, 
          ability: ability,
          is_task: false, 
          position: 0
        })

      assert %{title: ^title_string, ability: ^ability} = achievement
    end
  end

  test "get achievements from user if no goals in table" do 
    user = insert(:user)
    achievements = Achievements.all_achievements(user)

    assert [] = achievements
  end 
end 