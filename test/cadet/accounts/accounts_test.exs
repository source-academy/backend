defmodule Cadet.AccountsTest do
  @moduledoc """
  Some of the test values (i.e. tokens) in this file are specified in
  config/test.exs.
  """

  use Cadet.DataCase

  alias Cadet.{Accounts, Repo}
  alias Cadet.Accounts.{Query, User}

  # import Mock

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
      assert length(all_stu_in_c2) == 0
    end

    test "get all users in a group in a course", %{a1: admin1, g1: g1, g2: g2} do
      all_in_c1g1 = Accounts.get_users_by([group: g1.name], admin1)
      assert length(all_in_c1g1) == 2
      all_in_c1g2 = Accounts.get_users_by([group: g2.name], admin1)
      assert length(all_in_c1g2) == 0
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
      assert length(all_stu_in_c1g2) == 0
    end
  end

  describe "update_role" do
    setup do
      c1 = insert(:course, %{course_name: "c1"})
      c2 = insert(:course, %{course_name: "c2"})
      admin1 = insert(:course_registration, %{course: c1, role: :admin})
      staff1 = insert(:course_registration, %{course: c1, role: :staff})
      student1 = insert(:course_registration, %{course: c1, role: :student})
      student2 = insert(:course_registration, %{course: c2, role: :student})

      {:ok, %{a1: admin1, s1: student1, s2: student2, st1: staff1}}
    end

    test "successful when admin is admin of the course the user is in (student)", %{
      a1: admin1,
      s1: %{id: coursereg_id}
    } do
      {:ok, updated_coursereg} = Accounts.update_role(admin1, "student", coursereg_id)
      assert updated_coursereg.role == :student
    end

    test "successful when admin is admin of the course the user is in (staff)", %{
      a1: admin1,
      s1: %{id: coursereg_id}
    } do
      {:ok, updated_coursereg} = Accounts.update_role(admin1, "staff", coursereg_id)
      assert updated_coursereg.role == :staff
    end

    test "successful when admin is admin of the course the user is in (admin)", %{
      a1: admin1,
      s1: %{id: coursereg_id}
    } do
      {:ok, updated_coursereg} = Accounts.update_role(admin1, "admin", coursereg_id)
      assert updated_coursereg.role == :admin
    end

    test "admin is not admin of the course the user is in", %{a1: admin1, s2: %{id: coursereg_id}} do
      assert {:error, {:forbidden, "Wrong course"}} ==
               Accounts.update_role(admin1, "staff", coursereg_id)
    end

    test "invalid role provided", %{a1: admin1, s1: %{id: coursereg_id}} do
      assert {:error, {:bad_request, "role is invalid"}} =
               Accounts.update_role(admin1, "invalidrole", coursereg_id)
    end

    test "fails when staff makes changes", %{st1: staff1, s1: %{id: coursereg_id}} do
      assert {:error, {:forbidden, "User is not permitted to change others' roles"}} ==
               Accounts.update_role(staff1, "staff", coursereg_id)
    end
  end
end
