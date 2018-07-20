defmodule Cadet.Accounts.LoginTest do
  alias Cadet.Accounts.Form.Login

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Login

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{ivle_token: "T0K3N"})
    end

    test "invalid changeset" do
      assert_changeset(%{ivle_token: ""}, :invalid)
      assert_changeset(%{}, :invalid)
    end
  end
end
