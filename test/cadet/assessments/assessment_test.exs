defmodule Cadet.Assessments.AssessmentTest do
  alias Cadet.Assessments.Assessment

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Assessment

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{
        type: :mission,
        title: "mission",
        open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
        close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string()
      })

      assert_changeset(%{
        type: :mission,
        title: "mission",
        open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
        close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
        cover_picture: build_upload("test/fixtures/upload.png", "image/png"),
        mission_pdf: build_upload("test/fixtures/upload.pdf", "application/pdf")
      })
    end

    test "invalid changesets" do
      assert_changeset(%{type: :mission, title: "mission", max_xp: 100}, :invalid)

      assert_changeset(
        %{
          title: "mission",
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: 7),
          max_xp: 100
        },
        :invalid
      )
    end
  end
end
