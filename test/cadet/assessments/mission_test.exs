defmodule Cadet.Assessments.MissionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Mission

  valid_changesets Mission do
    %{category: :mission, title: "mission", open_at: Timex.now(), close_at: Timex.shift(Timex.now(), days: 7), max_xp: 100}
  end

  invalid_changesets Mission do
    %{category: :mission, title: "mission", open_at: Timex.now(), close_at: Timex.shift(Timex.now(), days: 7), max_xp: -100}
    %{category: :mission, title: "mission", max_xp: 100}
    %{title: "mission", open_at: Timex.now(), close_at: Timex.shift(Timex.now(), days: 7), max_xp: 100}
  end
end
