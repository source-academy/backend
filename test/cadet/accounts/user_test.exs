defmodule Cadet.Accounts.UserTest do
  alias Cadet.Accounts.User

  use Cadet.ChangesetCase, entity: User

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{name: "happy people", username: "people"}, :valid)
      assert_changeset(%{name: "happy", latest_viewed_id: 1}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{username: "people"}, :invalid)
      assert_changeset(%{role: :avenger}, :invalid)
    end
  end
end
