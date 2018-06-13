defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, :context

  alias Comeonin.Pbkdf2

  alias Cadet.Accounts.User
  alias Cadet.Accounts.Query
  alias Cadet.Accounts.Authorization
  alias Cadet.Accounts.Form.Registration

  @doc """
  Register new User entity using Cadet.Accounts.Form.Registration
  """
  def register(attrs = %{}, role) do
    changeset = Registration.changeset(%Registration{}, attrs)

    if changeset.valid?() do
      registration = apply_changes(changeset)

      Repo.transaction(fn ->
        attrs_with_role = Map.put(attrs, :role, role)
        {:ok, user} = create_user(attrs_with_role)

        {:ok, _} =
          create_authorization(
            %{
              provider: :nusnet_id,
              uid: registration.nusnet_id,
              token: Pbkdf2.hashpwsalt(registration.nusnet_id)
            },
            user
          )

        user
      end)
    else
      {:error, changeset}
    end
  end

  @doc """
  Creates Authorization entity with specified attributes.
  """
  def create_authorization(attrs = %{}, user = %User{}) do
    %Authorization{}
    |> Authorization.changeset(attrs)
    |> put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Creates User entity with specified attributes.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get the User entity with specified primary key.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Associate NUSTNET_ID with an existing `%User{}`
  """
  def add_nusnet_id(user = %User{}, nusnet_id) do
    token = get_token(:nusnet_id, nusnet_id) || get_random_token()

    changeset =
      %Authorization{}
      |> Authorization.changeset(%{
        provider: :nusnet_id,
        uid: nusnet_id,
        token: token
      })
      |> put_assoc(:user, user)

    Repo.insert(changeset)
  end

  @doc """
  Associate a NUSNET_ID to an existing `%User{}`
  """
  def set_nusnet_id(user = %User{}, nusnet_id) do
    token = Pbkdf2.hashpwsalt(nusnet_id)

    Repo.transaction(fn ->
      authorizations = Repo.all(Query.user_nusnet_ids(user.id))

      for nusnet_id <- authorizations do
        nusnet_id
        |> change(%{token: token})
        |> Repo.update!()
      end
    end)
  end

  @doc """
  Sign in using given NUSNET_ID
  """
  def sign_in(nusnet_id) do
    auth = Repo.one(Query.nusnet_id(nusnet_id))

    if auth == nil do
      {:error, :not_found}
    else
      auth = Repo.preload(auth, :user)
      {:ok, auth.user}
    end
  end

  defp get_token(provider, uid) do
    auth = Repo.get_by(Authorization, provider: provider, uid: uid)

    if auth == nil do
      nil
    else
      auth.token
    end
  end

  defp get_random_token() do
    length = 64

    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
