defmodule Cadet.Asessments.MissionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Mission

  valid_changesets Mission do
    %{order: "1", category: :mission, title: "Sound", summary_short: "short",
      summary_long: "long summary", open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), weeks: 2),
      file: "test/fixtures/upload.txt",
      cover_picture: "test/fixtures/upload.png"}
    %{order: "2", category: :sidequest, title: "EMP", open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), weeks: 3)}
  end

  invalid_changesets Mission do
    %{summary_short: "asd", summary_long: "ada"}
  end
end
