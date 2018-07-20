defmodule Cadet.Accounts.Form.RegistrationTest do
  alias Cadet.Accounts.Form.Registration

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Registration

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{name: "happy", nusnet_id: "e853820"}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{}, :invalid)
      assert_changeset(%{name: "happy"}, :invalid)
      assert_changeset(%{nusnet_id: "e853820"}, :invalid)
      assert_changeset(%{name: "", nusnet_id: ""}, :invalid)
      assert_changeset(%{name: "", nusnet_id: "e853820"}, :invalid)
      assert_changeset(%{name: "happy", nusnet_id: ""}, :invalid)
    end
  end
end
