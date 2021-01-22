defmodule Cadet.Incentives.AchievementPrerequisiteTest do
  alias Cadet.Incentives.AchievementPrerequisite

  use Cadet.ChangesetCase, entity: AchievementPrerequisite

  describe "Changesets" do
    test "valid params" do
      insert(:achievement, uuid: "d1fdae3f-2775-4503-ab6b-e043149d4a15")
      insert(:achievement, uuid: "d1fdae3f-2775-4503-ab6b-0123456789ab")

      assert_changeset_db(
        %{
          prerequisite_uuid: "d1fdae3f-2775-4503-ab6b-e043149d4a15",
          achievement_uuid: "d1fdae3f-2775-4503-ab6b-0123456789ab"
        },
        :valid
      )
    end
  end
end
