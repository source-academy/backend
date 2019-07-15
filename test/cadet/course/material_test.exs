defmodule Cadet.Course.MaterialTest do
  alias Cadet.Course.Material

  use Cadet.ChangesetCase, entity: Material

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          title: "File",
          file: build_upload("test/fixtures/upload.txt", "text/plain")
        },
        :valid
      )
    end

    test "invalid changeset" do
      assert_changeset(%{title: "", description: "some description"}, :invalid)
    end
  end
end
