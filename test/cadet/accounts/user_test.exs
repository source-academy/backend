defmodule Cadet.Accounts.UserTest do
  alias Cadet.Accounts.User

  use Cadet.ChangesetCase, entity: User

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{provider: "test", username: "luminus/E0000000"}, :valid)
      assert_changeset(%{provider: "test", username: "luminus/E0000001", name: "Avenger"}, :valid)
      assert_changeset(%{provider: "test", username: "happy", latest_viewed_course_id: 1}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{name: "people"}, :invalid)
      assert_changeset(%{latest_viewed_course_id: 1}, :invalid)
      assert_changeset(%{username: "luminus/E0000000"}, :invalid)
      assert_changeset(%{provider: "test"}, :invalid)
    end
  end
end
