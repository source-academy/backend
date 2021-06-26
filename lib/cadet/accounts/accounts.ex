defmodule Cadet.Accounts do
  @moduledoc """
  Accounts context contains domain logic for User management and Authentication
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Accounts.{Query, User, CourseRegistration}
  alias Cadet.Auth.Provider
  alias Cadet.Assessments.{Answer, Submission}

  @doc """
  Register new User entity using Cadet.Accounts.Form.Registration

  Returns {:ok, user} on success, otherwise {:error, changeset}
  """
  def register(attrs = %{username: username}) when is_binary(username) do
    attrs |> insert_or_update_user()
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
    case Repo.one(Query.username(username)) do
      nil ->
        # user is not registered in our database
        # :TODO recheck when designing onboarding process (assign role to module)
        # :TODO get_role process to be put in course creation?
        # with {:ok, role} <- Provider.get_role(provider, token),
        #      {:ok, name} <- Provider.get_name(provider, token),
        #      {:ok, _} <- register(%{name: name, username: username}, role) do
        #   sign_in(username, name, token)
        with {:ok, name} <- Provider.get_name(provider, token),
             {:ok, _} <- register(%{name: name, username: username}) do
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

  def update_latest_viewed(user = %User{}, latest_viewed_id) when is_ecto_id(latest_viewed_id) do
    case user
         |> User.changeset(%{latest_viewed_id: latest_viewed_id})
         |> Repo.update() do
      result = {:ok, _} -> result
      {:error, changeset} -> {:error, {:internal_server_error, full_error_messages(changeset)}}
    end
  end

  @update_role_roles ~w(admin)a
  def update_role(
        _admin_course_reg = %CourseRegistration{
          id: admin_course_reg_id,
          course_id: admin_course_id,
          role: admin_role
        },
        role,
        coursereg_id
      ) do
    with {:validate_role, true} <- {:validate_role, admin_role in @update_role_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != coursereg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^coursereg_id) |> Repo.one()},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id},
         {:update_db, {:ok, _} = result} <-
           {:update_db,
            user_course_reg |> CourseRegistration.changeset(%{role: role}) |> Repo.update()} do
      result
    else
      {:validate_role, false} ->
        {:error, {:forbidden, "User is not permitted to change others' roles"}}

      {:validate_not_self, false} ->
        {:error, {:bad_request, "Admin not allowed to downgrade own role"}}

      {:get_cr, _} ->
        {:error, {:bad_request, "User course registration does not exist"}}

      {:validate_same_course, false} ->
        {:error, {:forbidden, "Wrong course"}}

      {:update_db, {:error, changeset}} ->
        {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  @delete_user_roles ~w(admin)a
  def delete_user(
        _admin_course_reg = %CourseRegistration{
          id: admin_course_reg_id,
          course_id: admin_course_id,
          role: admin_role
        },
        coursereg_id
      ) do
    with {:validate_role, true} <- {:validate_role, admin_role in @delete_user_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != coursereg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^coursereg_id) |> Repo.one()},
         {:prevent_delete_admin, true} <- {:prevent_delete_admin, user_course_reg.role != :admin},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id} do
      # TODO: Handle deletions of achievement entries, etc. too

      # Delete submissions and answers before deleting user
      Submission
      |> where(student_id: ^user_course_reg.id)
      |> Repo.all()
      |> Enum.each(fn x ->
        Answer
        |> where(submission_id: ^x.id)
        |> Repo.delete_all()

        Repo.delete(x)
      end)

      Repo.delete(user_course_reg)
    else
      {:validate_role, false} ->
        {:error, {:forbidden, "User is not permitted to delete other users"}}

      {:validate_not_self, false} ->
        {:error, {:bad_request, "Admin not allowed to delete ownself from course"}}

      {:get_cr, _} ->
        {:error, {:bad_request, "User course registration does not exist"}}

      {:prevent_delete_admin, false} ->
        {:error, {:bad_request, "Admins cannot be deleted"}}

      {:validate_same_course, false} ->
        {:error, {:forbidden, "Wrong course"}}
    end
  end
end
