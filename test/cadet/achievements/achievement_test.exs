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
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
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
          open_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.to_unix() |> Integer.to_string()
        },
        :invalid
      )
    end
  end
end
