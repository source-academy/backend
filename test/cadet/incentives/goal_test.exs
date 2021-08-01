defmodule Cadet.Incentives.GoalTest do
  alias Cadet.Incentives.Goal
  alias Ecto.UUID

  use Cadet.ChangesetCase, entity: Goal

  describe "Changesets" do
    test "valid params" do
      course = insert(:course)

      assert_changeset_db(
        %{
          uuid: UUID.generate(),
          course_id: course.id,
          target_count: 1000,
          text: "Sample Text",
          type: "test_type",
          meta: %{}
        },
        :valid
      )
    end
  end
end
