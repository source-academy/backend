defmodule Cadet.AccountsTest do
  @moduledoc """
  Some tests in this module use pre-recorded HTTP responses saved by ExVCR.
  this allows testing without the use of actual external IVLE API calls.

  In the case that you need to change the recorded responses, you will need
  to set the two environment variables IVLE_KEY (used as a module attribute in
  `Cadet.Accounts.IVLE`) and TOKEN (used here). Don't forget to delete the
  cassette files, otherwise ExVCR will not override the cassettes.
  """

  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Accounts
  alias Cadet.Repo
  alias Cadet.Accounts.Query

  @token String.replace(inspect(System.get_env("TOKEN")), ~s("), "")

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
    user = insert(:user, name: "Teddy")
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
        {:ok, _} = Accounts.sign_in("e012345", @token)
        assert Repo.one(Query.nusnet_id("e012345")).uid == "e012345"
      end
    end

    test "registered user" do
      user = insert(:user)

      insert(:nusnet_id, %{
        uid: "e012345",
        user: user
      })

      assert {:ok, user} == Accounts.sign_in("e012345", @token)
    end

    test "invalid token" do
      use_cassette "accounts/sign_in#2" do
        assert {:error, :bad_request} == Accounts.sign_in("A0123456", "t0k3n")
      end
    end

    test "invalid nusnet id" do
      assert {:error, :internal_server_error} == Accounts.sign_in("", @token)
    end
  end
end
