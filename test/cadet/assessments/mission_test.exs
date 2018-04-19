defmodule Cadet.Asessments.MissionTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Mission

  @default_library %{
    version: 1,
    globals: [],
    externals: [],
    files: []
  }

  valid_changesets Mission do
    %{
      order: "1",
      category: :mission,
      title: "Sound",
      summary_short: "short",
      summary_long: "long summary",
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), weeks: 2),
      file: build_upload("test/fixtures/upload.txt"),
      cover_picture: build_upload("test/fixtures/upload.png"),
      max_xp: 0,
      raw_library: Poison.encode!(@default_library)
    }

    %{
      order: "2",
      category: :sidequest,
      title: "EMP",
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), weeks: 3),
      max_xp: 100,
      file: build_upload("test/fixtures/upload.txt"),
      raw_library: Poison.encode!(@default_library)
    }
  end

  invalid_changesets Mission do
    %{summary_short: "asd", summary_long: "ada"}

    %{
      order: "2",
      category: :sidequest,
      title: "EMP",
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), weeks: 3),
      max_xp: -100,
      file: build_upload("test/fixtures/upload.txt")
    }
  end
end
