defmodule Cadet.Course.MaterialTest do
  alias Cadet.Course.Material

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Material

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{name: "Lecture Notes", description: "This is lecture notes"}, :valid)

      assert_changeset(
        %{
          name: "File",
          file: build_upload("test/fixtures/upload.txt", "text/plain")
        },
        :valid
      )
    end

    test "invalid changeset" do
      assert_changeset(%{name: "", description: "some description"}, :invalid)
    end
  end
end
