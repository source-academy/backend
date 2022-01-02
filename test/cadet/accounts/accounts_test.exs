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
      provider: "test",
      name: "Test Name",
      username: "e0123456"
    }

    assert {:ok, user} = Accounts.register(attrs)
    assert %{name: "Test Name"} = user
  end

  describe "sign in using auth provider" do
    test "unregistered user" do
      {:ok, _user} = Accounts.sign_in("student", "student_token", "test")
      user = Repo.one(Query.username("student"))
      assert user.username == "student"

      # as set in config/test.exs
      assert user.name == "student 1"
    end

    test "pre-created user during first login" do
      insert(:user, %{username: "student", name: nil})
      {:ok, _user} = Accounts.sign_in("student", "student_token", "test")
      user = Repo.one(Query.username("student"))
      assert user.username == "student"

      # as set in config/test.exs
      assert user.name == "student 1"
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

    test_with_mock "upstream error", Cadet.Auth.Provider,
      get_name: fn _, _ -> {:error, :upstream, "Upstream error"} end do
      assert {:error, :bad_request, "Upstream error"} ==
               Accounts.sign_in("student", "student_token", "test")
    end
  end

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
    setup do
      c1 = insert(:course, %{course_name: "c1"})
      c2 = insert(:course, %{course_name: "c2"})
      admin1 = insert(:course_registration, %{course: c1, role: :admin})
      admin2 = insert(:course_registration, %{course: c2, role: :admin})
      g1 = insert(:group, %{course: c1})
      g2 = insert(:group, %{course: c1})
      insert(:course_registration, %{course: c1, group: g1, role: :student})
      insert(:course_registration, %{course: c1, group: g1, role: :student})

      {:ok, %{c1: c1, c2: c2, a1: admin1, a2: admin2, g1: g1, g2: g2}}
    end

    test "get all users in a course", %{a1: admin1, a2: admin2} do
      all_in_c1 = Accounts.get_users_by([], admin1)
      assert length(all_in_c1) == 3
      all_in_c2 = Accounts.get_users_by([], admin2)
      assert length(all_in_c2) == 1
    end

    test "get all students in a course", %{a1: admin1, a2: admin2} do
      all_stu_in_c1 = Accounts.get_users_by([role: :student], admin1)
      assert length(all_stu_in_c1) == 2
      all_stu_in_c2 = Accounts.get_users_by([role: :student], admin2)
      assert all_stu_in_c2 == []
    end

    test "get all users in a group in a course", %{a1: admin1, g1: g1, g2: g2} do
      all_in_c1g1 = Accounts.get_users_by([group: g1.name], admin1)
      assert length(all_in_c1g1) == 2
      all_in_c1g2 = Accounts.get_users_by([group: g2.name], admin1)
      assert all_in_c1g2 == []
    end

    test "get all students in a group in a course", %{c1: c1, a1: admin1, g1: g1, g2: g2} do
      insert(:course_registration, %{course: c1, group: g1, role: :staff})
      insert(:course_registration, %{course: c1, group: g2, role: :staff})
      all_in_c1g1 = Accounts.get_users_by([group: g1.name], admin1)
      assert length(all_in_c1g1) == 3
      all_in_c1g2 = Accounts.get_users_by([group: g2.name], admin1)
      assert length(all_in_c1g2) == 1
      all_stu_in_c1g1 = Accounts.get_users_by([group: g1.name, role: :student], admin1)
      assert length(all_stu_in_c1g1) == 2
      all_stu_in_c1g2 = Accounts.get_users_by([group: g2.name, role: :student], admin1)
      assert all_stu_in_c1g2 == []
    end
  end
end
