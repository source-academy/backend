defmodule Cadet.Assessments.LibraryTest do
  alias Cadet.Assessments.Library

  use Cadet.ChangesetCase, entity: Library

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{version: 1}, :valid)

      assert_changeset(
        %{
          version: 1,
          globals: ["asd"],
          externals: [],
          fields: []
        },
        :valid
      )
    end
  end
end
