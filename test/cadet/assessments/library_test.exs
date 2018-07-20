defmodule Cadet.Assessments.LibraryTest do
  alias Cadet.Assessments.Library

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Library

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{version: 1})

      assert_changeset(%{
        version: 1,
        globals: ["asd"],
        externals: [],
        fields: []
      })
    end
  end
end
