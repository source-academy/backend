defmodule CadetWeb.AdminUserController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.{Accounts, Courses}
  alias Cadet.Accounts.{CourseRegistrations, CourseRegistration}
  alias Cadet.Auth.Provider

  # This controller is used to find all users of a course

  def index(conn, filter) do
    users =
      filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "users.json", users: users)
  end

  @add_users_role ~w(admin)a
  def upsert_users_and_groups(conn, %{
        "course_id" => course_id,
        "users" => usernames_roles_groups,
        "provider" => provider
      }) do
    %{role: admin_role} = conn.assigns.course_reg

    {:ok, conn} =
      Repo.transaction(fn ->
        # Note: Usernames from frontend have not been namespaced yet
        with {:validate_role, true} <- {:validate_role, admin_role in @add_users_role},
             {:validate_provider, true} <-
               {:validate_provider,
                Map.has_key?(Application.get_env(:cadet, :identity_providers, %{}), provider)},
             {:atomify_keys, usernames_roles_groups} <-
               {:atomify_keys,
                Enum.map(usernames_roles_groups, fn x ->
                  for({key, val} <- x, into: %{}, do: {String.to_atom(key), val})
                end)},
             {:validate_usernames, true} <-
               {:validate_usernames,
                Enum.reduce(usernames_roles_groups, true, fn x, acc ->
                  acc and Map.has_key?(x, :username) and is_binary(x.username) and
                    x.username != ""
                end)},
             {:validate_roles, true} <-
               {:validate_roles,
                Enum.reduce(usernames_roles_groups, true, fn x, acc ->
                  acc and Map.has_key?(x, :role) and
                    String.to_atom(x.role) in Cadet.Accounts.Role.__enums__()
                end)},
             {:namespace, usernames_roles_groups} <-
               {:namespace,
                Enum.map(usernames_roles_groups, fn x ->
                  %{x | username: Provider.namespace(x.username, provider)}
                end)},
             {:upsert_users, :ok} <-
               {:upsert_users,
                Accounts.CourseRegistrations.upsert_users_in_course(
                  usernames_roles_groups,
                  course_id
                )},
             {:upsert_groups, :ok} <-
               {:upsert_groups,
                Courses.upsert_groups_in_course(usernames_roles_groups, course_id)} do
          text(conn, "OK")
        else
          {:validate_role, false} ->
            conn |> put_status(:forbidden) |> text("User is not permitted to add users")

          {:validate_provider, false} ->
            conn |> put_status(:bad_request) |> text("Invalid authentication provider")

          {:validate_usernames, false} ->
            conn |> put_status(:bad_request) |> text("Invalid username(s) provided")

          {:validate_roles, false} ->
            conn |> put_status(:bad_request) |> text("Invalid role(s) provided")

          {:upsert_users, {:error, {status, message}}} ->
            conn |> put_status(status) |> text(message)

          {:upsert_groups, {:error, {status, message}}} ->
            conn |> put_status(status) |> text(message)
        end
      end)

    conn
  end

  @update_role_roles ~w(admin)a
  def update_role(conn, %{"role" => role, "crId" => coursereg_id}) do
    %{id: admin_course_reg_id, role: admin_role, course_id: admin_course_id} =
      conn.assigns.course_reg

    with {:validate_role, true} <- {:validate_role, admin_role in @update_role_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != coursereg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^coursereg_id) |> Repo.one()},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id} do
      case CourseRegistrations.update_role(role, coursereg_id) do
        {:ok, %{}} ->
          text(conn, "OK")

        {:error, {status, message}} ->
          conn
          |> put_status(status)
          |> text(message)
      end
    else
      {:validate_role, false} ->
        conn |> put_status(:forbidden) |> text("User is not permitted to change others' roles")

      {:validate_not_self, false} ->
        conn |> put_status(:bad_request) |> text("Admin not allowed to downgrade own role")

      {:get_cr, _} ->
        conn |> put_status(:bad_request) |> text("User course registration does not exist")

      {:validate_same_course, false} ->
        conn |> put_status(:forbidden) |> text("User is in a different course")
    end
  end

  @delete_user_roles ~w(admin)a
  def delete_user(conn, %{"crId" => coursereg_id}) do
    %{id: admin_course_reg_id, role: admin_role, course_id: admin_course_id} =
      conn.assigns.course_reg

    with {:validate_role, true} <- {:validate_role, admin_role in @delete_user_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != coursereg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^coursereg_id) |> Repo.one()},
         {:prevent_delete_admin, true} <- {:prevent_delete_admin, user_course_reg.role != :admin},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id} do
      case CourseRegistrations.delete_course_registration(coursereg_id) do
        {:ok, %{}} ->
          text(conn, "OK")

        {:error, {status, message}} ->
          conn
          |> put_status(status)
          |> text(message)
      end
    else
      {:validate_role, false} ->
        conn |> put_status(:forbidden) |> text("User is not permitted to delete other users")

      {:validate_not_self, false} ->
        conn
        |> put_status(:bad_request)
        |> text("Admin not allowed to delete ownself from course")

      {:get_cr, _} ->
        conn |> put_status(:bad_request) |> text("User course registration does not exist")

      {:prevent_delete_admin, false} ->
        conn |> put_status(:bad_request) |> text("Admins cannot be deleted")

      {:validate_same_course, false} ->
        conn |> put_status(:forbidden) |> text("User is in a different course")
    end
  end

  swagger_path :index do
    get("/v2/courses/{course_id}/admin/users")

    summary("Returns a list of users in the course owned by the admin")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:AdminUserInfo))
    response(401, "Unauthorised")
  end

  swagger_path :add_users do
    put("/v2/courses/{course_id}/admin/users")

    summary("Adds the list of usernames and roles to the course")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      users(:body, Schema.array(:UsernameAndRole), "Array of usernames and roles", required: true)

      provider(:body, :string, "The authentication provider linked to these usernames",
        required: true
      )
    end

    response(200, "OK")
    response(400, "Bad Request. Invalid provider, username or role")
    response(403, "Forbidden. You are not an admin")
  end

  swagger_path :update_role do
    put("/v2/courses/{course_id}/admin/users/role")

    summary("Updates the role of the given user in the the course")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      role(:body, :role, "The new role", required: true)

      crId(:body, :integer, "The course registration of the user whose role is to be updated",
        required: true
      )
    end

    response(200, "OK")

    response(
      400,
      "Bad Request. User course registration does not exist or admin not allowed to downgrade own role"
    )

    response(403, "Forbidden. User is in different course, or you are not an admin")
  end

  swagger_path :delete_user do
    delete("/v2/courses/{course_id}/admin/users")

    summary("Deletes a user from a course")
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)

      crId(:body, :integer, "The course registration of the user whose role is to be updated",
        required: true
      )
    end

    response(200, "OK")

    response(
      400,
      "Bad Request. User course registration does not exist or admin not allowed to delete ownself from course or admins cannot be deleted"
    )

    response(403, "Forbidden. User is in different course, or you are not an admin")
  end

  def swagger_definitions do
    %{
      AdminUserInfo:
        swagger_schema do
          title("User")
          description("Basic information about the user in this course")

          properties do
            userId(:integer, "User's ID")
            name(:string, "Full name of the user")

            role(
              :string,
              "Role of the user in this course. Can be 'student', 'staff', or 'admin'"
            )

            group(
              :string,
              "Group the user belongs to in this course. May be null if the user does not belong to any group"
            )
          end
        end,
      UsernameAndRole:
        swagger_schema do
          title("Username and role")
          description("Username and role of the user to add to this course")

          properties do
            username(:string, "The user's username")
            role(:role, "The user's role. Can be 'student', 'staff', or 'admin'")
          end
        end
    }
  end
end
