defmodule Cadet.AccountsTest do
  use Cadet.DataCase

  alias Cadet.Accounts

  test "create user" do
    {:ok, user} =
      Accounts.create_user(%{
        name: "happy user",
        role: :student
      })

    assert user.name == "happy user"
    assert user.role == :student
  end

  test "invalid create user" do
    {:error, changeset} =
      Accounts.create_user(%{
        name: "happy user",
        role: :unknown
      })

    assert %{role: ["is invalid"]} = errors_on(changeset)
  end

  test "get existing user" do
    user = insert(:user, name: "Teddy")
    result = Accounts.get_user(user.id)
    assert result.name == "Teddy"
  end

  test "get unknown user" do
    refute Accounts.get_user(10_000)
  end

  test "associate nusnet_id to user" do
    user = insert(:user)
    {:ok, auth} = Accounts.add_nusnet_id(user, "teddy@happy.mail")
    assert auth.provider == :nusnet_id
    assert auth.uid == "teddy@happy.mail"
    assert auth.user_id == user.id
  end

  test "duplicate nusnet_id one user" do
    user = insert(:user)
    {:ok, _} = Accounts.add_nusnet_id(user, "teddy@happy.mail")
    {:error, changeset} = Accounts.add_nusnet_id(user, "teddy@happy.mail")
    assert %{uid: ["has already been taken"]} = errors_on(changeset)
  end

  test "duplicate nusnet_id different user" do
    user = insert(:user)
    {:ok, _} = Accounts.add_nusnet_id(user, "teddy@happy.mail")
    user2 = insert(:user)
    {:error, changeset} = Accounts.add_nusnet_id(user2, "teddy@happy.mail")
    assert %{uid: ["has already been taken"]} = errors_on(changeset)
  end

  test "setting user nusnet_id without e-mail" do
    user = insert(:user)
    assert {:ok, []} = Accounts.set_nusnet_id(user, "E012345")
  end

  # TODO: A user may not have multiple NUSNET_IDs?
  test "setting user nusnet_id with multiple e-mails" do
    user = insert(:user)
    insert(:nusnet_id, user: user)
    insert(:nusnet_id, user: user)
    assert {:ok, auths} = Accounts.set_nusnet_id(user, "E012345")
    assert length(auths) == 2
    assert Enum.all?(auths, &(&1.user_id == user.id))
  end

  test "create authorization" do
    user = insert(:user)

    attrs = %{
      provider: :nusnet_id,
      uid: "test@gmail.com",
      token: "hahaha"
    }

    assert {:ok, auth} = Accounts.create_authorization(attrs, user)
    assert auth.user_id == user.id
    assert auth.uid == "test@gmail.com"
  end

  test "valid registration" do
    attrs = %{
      name: "Test Name",
      nusnet_id: "E012345"
    }

    assert {:ok, user} = Accounts.register(attrs, :student)
    assert user.name == "Test Name"
  end

  describe "sign in using nusnet_id" do
    test "success" do
      user = insert(:user)

      insert(:nusnet_id, %{
        uid: "E012345",
        user: user
      })

      assert {:ok, user} == Accounts.sign_in("E012345", "t0k3n")
    end

    test "NUSNET ID not found" do
      assert {:error, :bad_request} == Accounts.sign_in("A0123456", "t0k3n")
    end
  end
end
