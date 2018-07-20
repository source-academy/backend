defmodule Cadet.Course.GroupTest do
  alias Cadet.Course.Group

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Group

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{}, :valid)
      assert_changeset(%{name: "tst"}, :valid)
    end
  end
end
