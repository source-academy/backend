defmodule Cadet.AccountsTest do
  use Cadet.DataCase

  alias Cadet.Accounts

  test "create user" do
    {:ok, user} =
      Accounts.create_user(%{
        first_name: "happy",
        last_name: "user",
        role: :student
      })

    assert(user.first_name == "happy")
    assert(user.last_name == "user")
    assert(user.role == :student)
  end

  test "invalid create user" do
    {:error, changeset} =
      Accounts.create_user(%{
        first_name: "happy",
        last_name: "user",
        role: :unknown
      })

    assert %{role: ["is invalid"]} = errors_on(changeset)
  end

  test "get existing user" do
    user = insert(:user, first_name: "Teddy")
    result = Accounts.get_user(user.id)
    assert result.first_name == "Teddy"
  end

  test "get unknown user" do
    refute Accounts.get_user(10000)
  end
end
