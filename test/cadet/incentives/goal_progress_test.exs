defmodule Cadet.Incentives.GoalProgressTest do
  alias Cadet.Incentives.GoalProgress

  use Cadet.ChangesetCase, entity: GoalProgress

  describe "Changesets" do
    test "valid params" do
      user = insert(:user)
      goal = insert(:goal)

      assert_changeset_db(
        %{
          goal_uuid: goal.uuid,
          user_id: user.id,
          xp: 500,
          completed: false
        },
        :valid
      )
    end
  end
end
