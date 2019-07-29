defmodule Cadet.Course.SourcecastTest do
  alias Cadet.Course.Sourcecast

  use Cadet.ChangesetCase, entity: Sourcecast

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          title: "Recording One",
          description: "This is a recording on rune mission",
          audio: build_upload("test/fixtures/upload.wav", "audio/wav"),
          playbackData:
            "{\"init\":{\"editorValue\":\"// Type your program in here!\"},\"inputs\":[]}"
        },
        :valid
      )
    end

    test "invalid changeset" do
      assert_changeset(
        %{title: "Recording One", description: "This is a recording on rune mission"},
        :invalid
      )

      assert_changeset(%{title: "", description: "Description"}, :invalid)
    end
  end
end
