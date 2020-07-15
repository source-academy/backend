defmodule Cadet.Achievments.AchievementPrerequisiteTest do
  alias Cadet.Achievements.AchievementPrerequisite

  use Cadet.ChangesetCase, entity: AchievementPrerequisite

  setup do
    achievement = insert(:achievement)

    valid_params = %{
      inferencer_id: achievement.id + 1,
      achievement_id: achievement.id
    }

    {:ok, %{achievement: achievement, valid_params: valid_params}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "converts valid params with models into ids", %{achievement: achievement} do
      assert_changeset_db(
        %{
          inferencer_id: achievement.id + 1,
          achievement_id: achievement.id
        },
        :valid
      )
    end
  end
end
