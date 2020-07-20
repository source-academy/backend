defmodule Cadet.Achievments.AchievementProgressTest do
  alias Cadet.Achievements.AchievementProgress

  use Cadet.ChangesetCase, entity: AchievementProgress

  describe "Changesets" do
    test "valid params" do
      user = insert(:user)
      achievement = insert(:achievement, id: 1)
      goal = insert(:achievement_goal, achievement_id: achievement.id, order: 0)

      assert_changeset_db(
        %{
          goal_id: goal.id,
          user_id: user.id,
          progress: 500
        },
        :valid
      )
    end
  end
end
