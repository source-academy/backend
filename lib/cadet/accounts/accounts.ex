defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Accounts.{Query, User}
  alias Cadet.Auth.Provider

  @doc """
  Register new User entity using Cadet.Accounts.Form.Registration

  Returns {:ok, user} on success, otherwise {:error, changeset}
  """
  def register(attrs = %{username: username}, role) when is_binary(username) do
    attrs |> Map.put(:role, role) |> insert_or_update_user()
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
  def insert_or_update_user(attrs = %{username: username}) when is_binary(username) do
    User
    |> where(username: ^username)
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
  Returns users matching a given set of criteria.
  """
  def get_users(filter \\ []) do
    User
    |> join(:left, [u], g in assoc(u, :group))
    |> preload([u, g], group: g)
    |> get_users(filter)
  end

  defp get_users(query, []), do: Repo.all(query)

  defp get_users(query, [{:group, group} | filters]),
    do: query |> where([u, g], g.name == ^group) |> get_users(filters)

  defp get_users(query, [filter | filters]), do: query |> where(^[filter]) |> get_users(filters)

  @spec sign_in(String.t(), Provider.token(), Provider.provider_instance()) ::
          {:error, :bad_request | :forbidden | :internal_server_error, String.t()} | {:ok, any}
  @doc """
  Sign in using given user ID
  """
  def sign_in(username, token, provider) do
    case Repo.one(Query.username(username)) do
      nil ->
        # user is not registered in our database
        with {:ok, role} <- Provider.get_role(provider, token),
             {:ok, name} <- Provider.get_name(provider, token),
             {:ok, _} <- register(%{name: name, username: username}, role) do
          sign_in(username, name, token)
        else
          {:error, :invalid_credentials, err} ->
            {:error, :forbidden, err}

          {:error, :upstream, err} ->
            {:error, :bad_request, err}

          {:error, _err} ->
            {:error, :internal_server_error}
        end

      user ->
        {:ok, user}
    end
  end

  def update_game_states(user = %User{}, new_game_state = %{}) do
    case user
         |> User.changeset(%{game_states: new_game_state})
         |> Repo.update() do
      result = {:ok, _} -> result
      {:error, changeset} -> {:error, {:internal_server_error, full_error_messages(changeset)}}
    end
  end
end
