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

  test "associate email to user" do
    user = insert(:user)
    {:ok, auth} = Accounts.add_email(user, "teddy@happy.mail")
    assert auth.provider == :email
    assert auth.uid == "teddy@happy.mail"
    assert auth.user_id == user.id
    assert byte_size(auth.token) > 0
  end

  test "duplicate email one user" do
    user = insert(:user)
    {:ok, _} = Accounts.add_email(user, "teddy@happy.mail")
    {:error, changeset} = Accounts.add_email(user, "teddy@happy.mail")
    assert %{uid: ["has already been taken"]} = errors_on(changeset)
  end

  test "duplicate email different user" do
    user = insert(:user)
    {:ok, _} = Accounts.add_email(user, "teddy@happy.mail")
    user2 = insert(:user)
    {:error, changeset} = Accounts.add_email(user2, "teddy@happy.mail")
    assert %{uid: ["has already been taken"]} = errors_on(changeset)
  end
end
