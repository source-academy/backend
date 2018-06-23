defmodule Cadet.Assessments.AssessmentTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Assessments.Assessment

  valid_changesets Assessment do
    %{
      category: :mission,
      title: "mission",
      open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
      close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
      max_xp: 100
    }

    %{
      category: :mission,
      title: "mission",
      open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
      close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
      max_xp: 100,
      cover_picture: build_upload("test/fixtures/upload.png", "image/png"),
      mission_pdf: build_upload("test/fixtures/upload.pdf", "application/pdf")
    }
  end

  invalid_changesets Assessment do
    %{
      category: :mission,
      title: "mission",
      open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
      close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
      max_xp: -100
    }

    %{category: :mission, title: "mission", max_xp: 100}

    %{
      title: "mission",
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), days: 7),
      max_xp: 100
    }
  end
end
