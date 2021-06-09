defmodule Cadet.AccountsTest do
  @moduledoc """
  Some of the test values (i.e. tokens) in this file are specified in
  config/test.exs.
  """

  use Cadet.DataCase

  alias Cadet.{Accounts, Repo}
  alias Cadet.Accounts.{Query, User}

  import Mock

  setup_all do
    HTTPoison.start()
  end

  test "get existing user" do
    user = insert(:user, name: "Teddy")
    result = Accounts.get_user(user.id)
    assert %{name: "Teddy"} = result
  end

  test "get unknown user" do
    refute Accounts.get_user(10_000)
  end

  test "valid registration" do
    attrs = %{
      name: "Test Name",
      username: "e0123456"
    }

    assert {:ok, user} = Accounts.register(attrs)
    assert %{name: "Test Name"} = user
  end

  describe "sign in using auth provider" do
    test "unregistered user" do
      {:ok, _user} = Accounts.sign_in("student", "student_token", "test")
      assert Repo.one(Query.username("student")).username == "student"
    end

    test "registered user" do
      user =
        insert(:user, %{
          username: "student"
        })

      assert {:ok, user} == Accounts.sign_in("student", "student_token", "test")
    end

    test "invalid token" do
      assert {:error, :forbidden, "Invalid token"} ==
               Accounts.sign_in("student", "invalid_token", "test")
    end

    # test_with_mock "upstream error", Cadet.Auth.Provider,
    #   get_role: fn _, _ -> {:error, :upstream, "Upstream error"} end do
    #   assert {:error, :bad_request, "Upstream error"} ==
    #            Accounts.sign_in("student", "student_token", "test")
    # end
  end

  # describe "sign in with unregistered user gets the right roles" do
  #   test ~s(user has admin access) do
  #     assert {:ok, user} = Accounts.sign_in("admin", "admin_token", "test")
  #     assert %{role: :admin} = user
  #   end

  #   test ~s(user has staff access) do
  #     assert {:ok, user} = Accounts.sign_in("staff", "staff_token", "test")
  #     assert %{role: :staff} = user
  #   end

  #   test ~s(user has student access) do
  #     assert {:ok, user} = Accounts.sign_in("student", "student_token", "test")
  #     assert %{role: :student} = user
  #   end
  # end

  describe "insert_or_update_user" do
    test "existing user" do
      user = insert(:user)
      user_params = params_for(:user, username: user.username)
      Accounts.insert_or_update_user(user_params)

      updated_user =
        User
        |> where(username: ^user.username)
        |> Repo.one()

      assert updated_user.id == user.id
      assert updated_user.name == user_params.name
    end

    test "non-existing user" do
      user_params = params_for(:user)
      Accounts.insert_or_update_user(user_params)

      updated_user =
        User
        |> where(username: ^user_params.username)
        |> Repo.one()

      assert updated_user.name == user_params.name
    end
  end

  describe "get_users_by" do
    test "get all users in a course" do

    end

    test "get all students in a course" do

    end

    test "get all users in a group in a course" do

    end

    test "get all students in a group in a course" do

    end
  end
end
