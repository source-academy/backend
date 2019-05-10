defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, :context

  import Ecto.Query

  alias Cadet.Accounts.Form.Registration
  alias Cadet.Accounts.{Authorization, Luminus, Query, User}

  @doc """
  Register new User entity using Cadet.Accounts.Form.Registration

  Returns {:ok, user} on success, otherwise {:error, changeset}
  """
  def register(attrs = %{nusnet_id: nusnet_id}, role) when is_binary(nusnet_id) do
    changeset = Registration.changeset(%Registration{}, attrs)

    if changeset.valid? do
      registration = apply_changes(changeset)

      Repo.transaction(fn ->
        attrs_with_role = Map.put(attrs, :role, role)
        {:ok, user} = insert_or_update_user(attrs_with_role)

        {:ok, _} =
          create_authorization(
            %{
              provider: :nusnet_id,
              uid: registration.nusnet_id
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
  Updates User entity with specified attributes. If the User does not exist yet,
  create one.
  """
  @spec insert_or_update_user(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update_user(attrs = %{nusnet_id: nusnet_id}) when is_binary(nusnet_id) do
    User
    |> where(nusnet_id: ^nusnet_id)
    |> Repo.one()
    |> case do
      nil ->
        User.changeset(%User{}, attrs)

      user ->
        User.changeset(user, attrs)
    end
    |> Repo.insert_or_update()
  end

  @doc """
  Get the User entity with specified primary key.
  """
  def get_user(id) when is_ecto_id(id) do
    Repo.get(User, id)
  end

  @doc """
  Associate NUSTNET_ID with an existing `%User{}`
  """
  def add_nusnet_id(user = %User{}, nusnet_id) do
    changeset =
      %Authorization{}
      |> Authorization.changeset(%{
        provider: :nusnet_id,
        uid: nusnet_id
      })
      |> put_assoc(:user, user)

    Repo.insert(changeset)
  end

  @doc """
  Associate a NUSNET_ID to an existing `%User{}`
  """
  def set_nusnet_id(user = %User{}, nusnet_id) do
    Repo.transaction(fn ->
      authorizations = Repo.all(Query.user_nusnet_ids(user.id))

      for authorization <- authorizations do
        authorization
        |> change(%{nusnet_id: nusnet_id})
        |> Repo.update!()
      end
    end)
  end

  @doc """
  Sign in using given NUSNET_ID
  """
  def sign_in(nusnet_id, name, token) do
    auth = Repo.one(Query.nusnet_id(nusnet_id))

    if auth do
      auth = Repo.preload(auth, :user)
      {:ok, auth.user}
    else
      # user is not registered in our database
      with {:ok, role} <- Luminus.fetch_role(token),
           {:ok, _} <- register(%{name: name, nusnet_id: nusnet_id}, role) do
        sign_in(nusnet_id, name, token)
      else
        {:error, :forbidden} ->
          # Luminus.fetch_*/1 responds with :forbidden if student does not read CS1101S
          {:error, :forbidden}

        {:error, :bad_request} ->
          # Luminus.fetch_*/1 responds with :bad_request if token is invalid
          {:error, :bad_request}

        {:error, _} ->
          # Luminus.fetch_role/1 responds with :internal_server_error if API key is invalid
          # register/2 returns {:error, changeset} if changeset is invalid
          {:error, :internal_server_error}
      end
    end
  end
end
