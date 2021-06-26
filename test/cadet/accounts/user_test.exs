defmodule Cadet.Accounts.UserTest do
  alias Cadet.Accounts.User

  use Cadet.ChangesetCase, entity: User

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{username: "luminus/E0000000"}, :valid)
      assert_changeset(%{username: "luminus/E0000001", name: "Avenger"}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{name: "people"}, :invalid)
      assert_changeset(%{role: :avenger}, :invalid)
    end
  end
end
