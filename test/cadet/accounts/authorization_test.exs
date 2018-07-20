defmodule Cadet.Accounts.AuthorizationTest do
  alias Cadet.Accounts.Authorization

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Authorization

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{provider: :nusnet_id, uid: "E012345", user_id: 2})
    end

    test "invalid changesets" do
      assert_changeset(%{provider: :nusnet_id, uid: "", user_id: 2}, :invalid)
      assert_changeset(%{provider: :facebook, uid: "E012345", user_id: :unknown}, :invalid)
      assert_changeset(%{provider: :email, user_id: 2}, :invalid)
    end
  end
end
