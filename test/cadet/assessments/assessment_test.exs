defmodule Cadet.Assessments.AssessmentTest do
  alias Cadet.Assessments.Assessment

  use Cadet.ChangesetCase, entity: Assessment

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          type: :mission,
          title: "mission",
          number: "M#{Enum.random(0..10)}",
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string()
        },
        :valid
      )

      assert_changeset(
        %{
          type: :mission,
          title: "mission",
          number: "M#{Enum.random(0..10)}",
          open_at: Timex.now() |> Timex.to_unix() |> Integer.to_string(),
          close_at: Timex.now() |> Timex.shift(days: 7) |> Timex.to_unix() |> Integer.to_string(),
          cover_picture: build_upload("test/fixtures/upload.png", "image/png"),
          mission_pdf: build_upload("test/fixtures/upload.pdf", "application/pdf")
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(%{type: :mission, title: "mission", max_grade: 100}, :invalid)

      assert_changeset(
        %{
          title: "mission",
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: 7),
          max_grade: 100
        },
        :invalid
      )
    end
  end
end
