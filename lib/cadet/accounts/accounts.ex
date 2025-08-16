defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger

  alias Cadet.Accounts.{Query, User, CourseRegistration}
  alias Cadet.Auth.Provider

  @doc """
  Register new User entity using Cadet.Accounts.Form.Registration

  Returns {:ok, user} on success, otherwise {:error, changeset}
  """
  def register(attrs = %{username: username, provider: _provider}) when is_binary(username) do
    attrs |> insert_or_update_user()
  end

  @doc """
  Updates User entity with specified attributes. If the User does not exist yet,
  create one.
  """
  @spec insert_or_update_user(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update_user(attrs = %{username: username, provider: provider})
      when is_binary(username) do
    User
    |> where(username: ^username)
    |> where(provider: ^provider)
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

  @get_all_role ~w(admin staff)a
  @doc """
  Returns users matching a given set of criteria.
  """
  def get_users_by(filter \\ [], %CourseRegistration{course_id: course_id, role: role})
      when role in @get_all_role do
    CourseRegistration
    |> where([cr], cr.course_id == ^course_id)
    |> join(:inner, [cr], u in assoc(cr, :user))
    |> preload([cr, u], user: u)
    |> join(:left, [cr, u], g in assoc(cr, :group))
    |> preload([cr, u, g], group: g)
    |> get_users_helper(filter)
  end

  defp get_users_helper(query, []), do: Repo.all(query)

  defp get_users_helper(query, [{:group, group} | filters]),
    do: query |> where([cr, u, g], g.name == ^group) |> get_users_helper(filters)

  defp get_users_helper(query, [filter | filters]),
    do: query |> where(^[filter]) |> get_users_helper(filters)

  @spec sign_in(String.t(), Provider.token(), Provider.provider_instance()) ::
          {:error, :bad_request | :forbidden | :internal_server_error, String.t()} | {:ok, any}
  @doc """
  Sign in using given user ID
  """
  def sign_in(username, token, provider) do
    user = username |> Query.username() |> where(provider: ^provider) |> Repo.one()

    if is_nil(user) or is_nil(user.name) do
      # user is not registered in our database or does not have a name
      # (accounts pre-created by instructors do not have a name, and has to be fetched
      #  from the auth provider during sign_in)
      with {:ok, name} <- Provider.get_name(provider, token),
           {:ok, _} <- register(%{provider: provider, name: name, username: username}) do
        sign_in(username, token, provider)
      else
        {:error, :invalid_credentials, err} ->
          {:error, :forbidden, err}

        {:error, :upstream, err} ->
          {:error, :bad_request, err}

        {:error, _err} ->
          {:error, :internal_server_error}
      end
    else
      {:ok, user}
    end
  end

  def update_latest_viewed(user = %User{id: user_id}, latest_viewed_course_id)
      when is_ecto_id(latest_viewed_course_id) do
    Logger.info("Updating latest viewed course for user #{user_id} to #{latest_viewed_course_id}")

    CourseRegistration
    |> where(user_id: ^user_id)
    |> where(course_id: ^latest_viewed_course_id)
    |> Repo.one()
    |> case do
      nil ->
        Logger.error("User #{user_id} is not enrolled in course #{latest_viewed_course_id}")
        {:error, {:bad_request, "user is not in the course"}}

      _ ->
        case user
             |> User.changeset(%{latest_viewed_course_id: latest_viewed_course_id})
             |> Repo.update() do
          result = {:ok, _} ->
            Logger.info("Successfully updated latest viewed course for user")
            result

          {:error, changeset} ->
            error_msg = full_error_messages(changeset)
            Logger.error("Failed to update latest viewed course for user: #{error_msg}")
            {:error, {:internal_server_error, error_msg}}
        end
    end
  end
end
