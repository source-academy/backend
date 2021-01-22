defmodule Cadet.Incentives.AchievementToGoalTest do
  alias Cadet.Incentives.AchievementToGoal

  use Cadet.ChangesetCase, entity: AchievementToGoal

  describe "Changesets" do
    test "valid changesets" do
      insert(:achievement, uuid: "d1fdae3f-2775-4503-ab6b-e043149d4a15")
      insert(:goal, uuid: "d1fdae3f-2775-4503-ab6b-0123456789ab")

      assert_changeset_db(
        %{
          achievement_uuid: "d1fdae3f-2775-4503-ab6b-e043149d4a15",
          goal_uuid: "d1fdae3f-2775-4503-ab6b-0123456789ab"
        },
        :valid
      )
    end
  end
end
