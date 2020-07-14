defmodule Cadet.Achievments.AchievementTest do
  alias Cadet.Achievements.Achievement

  use Cadet.ChangesetCase, entity: Achievement

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          inferencer_id: 0,
          id: 0,
          title: "Hello World",
          ability: :Core,
          open_at: DateTime.from_naive!(~N[2016-05-24 13:26:08.003], "Etc/UTC"),
          close_at: DateTime.from_naive!(~N[2016-05-27 13:26:08.003], "Etc/UTC"),
          is_task: false
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(
        %{
          inferencer_id: 0,
          id: 0,
          title: "Hello World",
          ability: :Core,
          open_at: DateTime.from_naive!(~N[2016-05-27 13:26:08.003], "Etc/UTC"),
          close_at: DateTime.from_naive!(~N[2016-05-24 13:26:08.003], "Etc/UTC")
        },
        :invalid
      )
    end
  end
end
