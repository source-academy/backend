defmodule Cadet.Incentives.GoalProgressTest do
  alias Cadet.Incentives.GoalProgress

  use Cadet.ChangesetCase, entity: GoalProgress

  describe "Changesets" do
    test "valid params" do
      course_reg = insert(:course_registration)
      goal = insert(:goal)

      assert_changeset_db(
        %{
          goal_uuid: goal.uuid,
          course_reg_id: course_reg.id,
          count: 500,
          completed: false
        },
        :valid
      )
    end
  end
end
