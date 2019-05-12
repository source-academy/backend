defmodule Cadet.AccountsTest do
  @moduledoc """
  Some tests in this module use pre-recorded HTTP responses saved by ExVCR.
  this allows testing without the use of actual external LumiNUS API calls.

  In the case that you need to change the recorded responses, you will need
  to set all the luminus config variables (used as a module attribute in
  `Cadet.Accounts.Luminus`) and environment variable CODE (used here). Don't
  forget to delete the cassette files, otherwise ExVCR will not override the
  cassettes. You can set the TOKEN environment variable like so,

    CODE=auth_code_goes_here mix test

  Code refers to the authorization code generated via the OAuth Authorization
  Grant Type. More information can be found here

  https://wiki.nus.edu.sg/pages/viewpage.action?pageId=235638755.
  """

  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.{Accounts, Repo}
  alias Cadet.Accounts.{Query, Luminus, User}

  @token Luminus.fetch_luminus_token_or_return_default(System.get_env("CODE"))

  setup_all do
    HTTPoison.start()
  end

  test "create user" do
    {:ok, user} =
      Accounts.create_user(%{
        name: "happy user",
        role: :student
      })

    assert %{name: "happy user", role: :student} = user
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
    user = insert(:user, name: "Teddy", role: :student)
    result = Accounts.get_user(user.id)
    assert %{name: "Teddy", role: :student} = result
  end

  test "get unknown user" do
    refute Accounts.get_user(10_000)
  end

  test "associate nusnet_id to user" do
    user = insert(:user)
    {:ok, auth} = Accounts.add_nusnet_id(user, "e012345")
    assert %{uid: "e012345", provider: :nusnet_id, user: ^user} = auth
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
      uid: "e012345",
      token: "hahaha"
    }

    assert {:ok, auth} = Accounts.create_authorization(attrs, user)
    assert %{uid: "e012345", provider: :nusnet_id, user: ^user} = auth
  end

  test "valid registration" do
    attrs = %{
      name: "Test Name",
      nusnet_id: "e012345"
    }

    assert {:ok, user} = Accounts.register(attrs, :student)
    assert %{name: "Test Name", role: :student} = user
  end

  describe "sign in using nusnet_id" do
    test "unregistered user" do
      use_cassette "accounts/sign_in#1" do
        {:ok, _} = Accounts.sign_in("e012345", "TOM", @token)
        assert Repo.one(Query.nusnet_id("e012345")).uid == "e012345"
      end
    end

    test "registered user" do
      user = insert(:user)

      insert(:nusnet_id, %{
        uid: "e012345",
        user: user
      })

      assert {:ok, user} == Accounts.sign_in("e012345", "TOM", @token)
    end

    test "invalid token" do
      use_cassette "accounts/sign_in#2" do
        assert {:error, :bad_request} == Accounts.sign_in("A0123456", "TOM", "t0k3n")
      end
    end

    test "invalid nusnet id" do
      use_cassette "accounts/sign_in#3" do
        assert {:error, :internal_server_error} == Accounts.sign_in("", "TOM", @token)
      end
    end
  end

  describe "sign in with unregistered user gets the right roles" do
    test ~s(user has admin access) do
      use_cassette "accounts/sign_in#4", custom: true do
        assert {:ok, user} = Accounts.sign_in("e012345", "TOM", @token)
        assert %{role: :admin} = user
      end
    end

    test ~s(user has staff access) do
      use_cassette "accounts/sign_in#5", custom: true do
        assert {:ok, user} = Accounts.sign_in("e012345", "TOM", @token)
        assert %{role: :staff} = user
      end
    end

    test ~s(user has student access) do
      use_cassette "accounts/sign_in#6", custom: true do
        assert {:ok, user} = Accounts.sign_in("e012345", "TOM", @token)
        assert %{role: :student} = user
      end
    end

    test ~s(user cs1101s module is inactive) do
      use_cassette "accounts/sign_in#7", custom: true do
        assert {:error, :forbidden} = Accounts.sign_in("e012345", "TOM", @token)
      end
    end

    test ~s(user does not read cs1101s) do
      use_cassette "accounts/sign_in#8", custom: true do
        assert {:error, :forbidden} = Accounts.sign_in("e012345", "TOM", @token)
      end
    end
  end

  describe "insert_or_update_user" do
    test "existing user" do
      user = insert(:user)
      user_params = params_for(:user, nusnet_id: user.nusnet_id)
      Accounts.insert_or_update_user(user_params)

      updated_user =
        User
        |> where(nusnet_id: ^user.nusnet_id)
        |> Repo.one()

      assert updated_user.id == user.id
      assert updated_user.name == user_params.name
      assert updated_user.role == user_params.role
    end

    test "non-existing user" do
      user_params = params_for(:user)
      Accounts.insert_or_update_user(user_params)

      updated_user =
        User
        |> where(nusnet_id: ^user_params.nusnet_id)
        |> Repo.one()

      assert updated_user.name == user_params.name
      assert updated_user.role == user_params.role
    end
  end
end
