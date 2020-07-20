defmodule Cadet.Achievments.AchievementPrerequisiteTest do
  alias Cadet.Achievements.AchievementPrerequisite

  use Cadet.ChangesetCase, entity: AchievementPrerequisite

  describe "Changesets" do
    test "valid params" do
      insert(:achievement, id: 1)
      insert(:achievement, id: 2)

      assert_changeset_db(
        %{
          prerequisite_id: 1,
          achievement_id: 2
        },
        :valid
      )
    end
  end
end
