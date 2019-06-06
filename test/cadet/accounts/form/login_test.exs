defmodule Cadet.Accounts.LoginTest do
  alias Cadet.Accounts.Form.Login

  use Cadet.ChangesetCase, entity: Login

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{luminus_code: "C0dE"}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{luminus_code: ""}, :invalid)
      assert_changeset(%{}, :invalid)
    end
  end
end
