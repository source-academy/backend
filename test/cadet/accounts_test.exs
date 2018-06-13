defmodule Cadet.AccountsTest do
  use Cadet.DataCase

  alias Cadet.Accounts

  test "create user" do
    {:ok, user} =
      Accounts.create_user(%{
        name: "happy user",
        nusnet_id: "e948329",
        role: :student
      })

    assert user.name == "happy user"
    assert user.nusnet_id == "e948329"
    assert user.role == :student
  end

  test "invalid create user" do
    {:error, changeset} =
      Accounts.create_user(%{
        name: "happy user",
        nusnet_id: "e483921",
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
    assert byte_size(auth.token) > 0
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

  test "setting user password without e-mail" do
    user = insert(:user)
    assert {:ok, []} = Accounts.set_password(user, "newpassword")
  end

  test "setting user password with multiple e-mails" do
    user = insert(:user)
    insert(:nusnet_id, user: user)
    insert(:nusnet_id, user: user)
    assert {:ok, auths} = Accounts.set_password(user, "newpassword")
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
      nusnet_id: "e948203",
      password: "somepassword",
      password_confirmation: "somepassword"
    }

    assert {:ok, user} = Accounts.register(attrs, :student)
    assert user.name == "Test Name"
    assert user.nusnet_id == "e948203"
  end

  test "register password confirmation does not match" do
    attrs = %{
      name: "Test",
      nusnet_id: "e839182",
      password: "somepassword2",
      password_confirmation: "somepassword"
    }

    assert {:error, changeset} = Accounts.register(attrs, :student)
    assert %{password_confirmation: ["does not match confirmation"]} == errors_on(changeset)
  end

  describe "sign in using e-mail and password" do
    test "success" do
      user = insert(:user)

      nusnet_id =
        insert(:nusnet_id, %{
          token: Pbkdf2.hash_pwd_salt("somepassword"),
          user: user
        })

      assert {:ok, user} == Accounts.sign_in(nusnet_id.uid, "somepassword")
    end

    test "e-mail not found" do
      assert {:error, :not_found} == Accounts.sign_in("unknown@mail.com", "somepassword")
    end

    test "invalid password" do
      user = insert(:user)

      nusnet_id =
        insert(:nusnet_id, %{
          token: Pbkdf2.hash_pwd_salt("somepassword"),
          user: user
        })

      assert {:error, :invalid_password} == Accounts.sign_in(nusnet_id.uid, "somepassword2")
    end
  end
end
