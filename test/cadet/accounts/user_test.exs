defmodule Cadet.Accounts.UserTest do
  alias Cadet.Accounts.User

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: User

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{name: "happy people", role: :admin}, :valid)
      assert_changeset(%{name: "happy", role: :student}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{name: "people"}, :invalid)
      assert_changeset(%{role: :avenger}, :invalid)
    end
  end
end
