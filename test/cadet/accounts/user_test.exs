defmodule Cadet.Accounts.UserTest do
  alias Cadet.Accounts.User

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: User

  describe "Changesets" do
    test "valid changeset" do
      test_changeset(%{name: "happy people", role: :admin})
      test_changeset(%{name: "happy", role: :student})
    end

    test "invalid changeset" do
      test_changeset_db(%{name: "people"}, :invalid)
      test_changeset(%{role: :avenger}, :invalid)
    end
  end
end
