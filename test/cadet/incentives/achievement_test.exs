defmodule Cadet.Incentives.AchievementTest do
  alias Cadet.Incentives.Achievement

  use Cadet.ChangesetCase, entity: Achievement

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          uuid: "d1fdae3f-2775-4503-ab6b-e043149d4a15",
          title: "Hello World",
          ability: "Core",
          open_at: DateTime.from_naive!(~N[2016-05-24 13:26:08.003], "Etc/UTC"),
          close_at: DateTime.from_naive!(~N[2016-05-27 13:26:08.003], "Etc/UTC"),
          is_task: false,
          position: 0
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(
        %{
          uuid: "d1fdae3f-2775-4503-ab6b-e043149d4a15",
          title: "Hello World",
          ability: "Core",
          open_at: DateTime.from_naive!(~N[2016-05-27 13:26:08.003], "Etc/UTC"),
          close_at: DateTime.from_naive!(~N[2016-05-24 13:26:08.003], "Etc/UTC")
        },
        :invalid
      )
    end
  end
end
