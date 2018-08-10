defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, :context
  import Ecto.Query

  alias Cadet.Accounts.Authorization
  alias Cadet.Accounts.IVLE
  alias Cadet.Accounts.User
  alias Cadet.Accounts.Query
  alias Cadet.Accounts.Form.Registration

  @doc """
  Register new User entity using Cadet.Accounts.Form.Registration

  Returns {:ok, user} on success, otherwise {:error, changeset}
  """
  def register(attrs = %{}, role) do
    changeset = Registration.changeset(%Registration{}, attrs)

    if changeset.valid? do
      registration = apply_changes(changeset)

      Repo.transaction(fn ->
        attrs_with_role = Map.put(attrs, :role, role)
        {:ok, user} = create_user(attrs_with_role)

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
  Get the User entity with specified primary key.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Get student with given name and nusnet id or create one
  """
  def get_or_create_user(name, role, nusnet_id) do
    query =
      from(
        u in User,
        where: u.name == ^name and u.role == ^role and u.nusnet_id == ^nusnet_id
      )

    users = Repo.all(query)

    if length(users) != 0 do
      List.first(users)
    else
      elem(create_user(%{name: name, role: role, nusnet_id: nusnet_id}), 1)
    end
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
  def sign_in(nusnet_id, token) do
    auth = Repo.one(Query.nusnet_id(nusnet_id))

    if auth do
      auth = Repo.preload(auth, :user)
      {:ok, auth.user}
    else
      # user is not registered in our database
      with {:ok, name} <- IVLE.fetch_name(token),
           {:ok, role} <- IVLE.fetch_role(token),
           {:ok, _} <- register(%{name: name, nusnet_id: nusnet_id}, role) do
        sign_in(nusnet_id, token)
      else
        {:error, :bad_request} ->
          # IVLE.fetch_*/1 responds with :bad_request if token is invalid
          {:error, :bad_request}

        {:error, _} ->
          # IVLE.fetch_*/1 responds with :internal_server_error if API key is invalid
          # register/2 returns {:error, changeset} if changeset is invalid
          {:error, :internal_server_error}
      end
    end
  end
end
