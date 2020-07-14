defmodule Cadet.Achievments.AchievementGoalTest do
  alias Cadet.Achievements.AchievementGoal

  use Cadet.ChangesetCase, entity: AchievementGoal

  setup do
    achievement = insert(:achievement)
    user = insert(:user, %{role: :student})

    valid_params = %{
      goal_id: 0,
      goal_text: "Sample Text",
      goal_progress: 0,
      goal_target: 0,
      user_id: user.id,
      achievement_id: achievement.id
    }

    {:ok, %{achievement: achievement, user: user, valid_params: valid_params}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "converts valid params with models into ids", %{achievement: achievement, user: user} do
      assert_changeset_db(
        %{
          goal_id: 0,
          goal_text: "Sample Text",
          goal_progress: 0,
          goal_target: 0,
          user_id: user.id,
          achievement_id: achievement.id
        },
        :valid
      )
    end
  end
end
