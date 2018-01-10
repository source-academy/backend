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

    assert user.first_name == "happy"
    assert user.last_name == "user"
    assert user.role == :student
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

  test "setting user password without e-mail" do
    user = insert(:user)
    assert {:ok, []} = Accounts.set_password(user, "newpassword")
  end

  test "setting user password with multiple e-mails" do
    user = insert(:user)
    insert(:email, user: user)
    insert(:email, user: user)
    assert {:ok, auths} = Accounts.set_password(user, "newpassword")
    assert length(auths) == 2
    assert Enum.all?(auths, &(&1.user_id == user.id))
  end

  test "create authorization" do
    user = insert(:user)

    attrs = %{
      provider: :email,
      uid: "test@gmail.com",
      token: "hahaha"
    }

    assert {:ok, auth} = Accounts.create_authorization(attrs, user)
    assert auth.user_id == user.id
    assert auth.uid == "test@gmail.com"
  end

  test "valid registration" do
    attrs = %{
      first_name: "Test",
      last_name: "Name",
      email: "test@gmail.com",
      password: "somepassword",
      password_confirmation: "somepassword"
    }

    assert {:ok, user} = Accounts.register(attrs, :student)
    assert user.first_name == "Test"
    assert user.last_name == "Name"
  end

  test "register using invalid email format" do
    attrs = %{
      first_name: "Test",
      email: "testgmail.com",
      password: "somepassword",
      password_confirmation: "somepassword"
    }

    assert {:error, changeset} = Accounts.register(attrs, :student)
    assert %{email: ["has invalid format"]} == errors_on(changeset)
  end

  test "register password confirmation does not match" do
    attrs = %{
      first_name: "Test",
      email: "test@gmail.com",
      password: "somepassword2",
      password_confirmation: "somepassword"
    }

    assert {:error, changeset} = Accounts.register(attrs, :student)
    assert %{password_confirmation: ["does not match confirmation"]} == errors_on(changeset)
  end
end
