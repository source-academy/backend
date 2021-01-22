defmodule Cadet.Incentives.GoalTest do
  alias Cadet.Incentives.Goal
  alias Ecto.UUID

  use Cadet.ChangesetCase, entity: Goal

  describe "Changesets" do
    test "valid params" do
      assert_changeset_db(
        %{
          uuid: UUID.generate(),
          max_xp: 1000,
          text: "Sample Text",
          type: "test_type",
          meta: %{}
        },
        :valid
      )
    end
  end
end
