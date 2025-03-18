defmodule CadetWeb.AdminUserController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.{Accounts, Assessments, Courses}
  alias Cadet.Accounts.{CourseRegistrations, CourseRegistration, Role}

  # This controller is used to find all users of a course

  def index(conn, filter) do
    users =
      filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "users.json", users: users)
  end

  def combined_total_xp(conn, %{"course_reg_id" => course_reg_id}) do
    course_reg = Repo.get(CourseRegistration, course_reg_id)

    course_id = course_reg.course_id
    user_id = course_reg.user_id
    course_reg_id = course_reg.id

    total_xp = Assessments.user_total_xp(course_id, user_id, course_reg_id)
    json(conn, %{totalXp: total_xp})
  end

  @add_users_role ~w(admin)a
  def get_students(conn, filter) do
    users =
      filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "get_students.json", users: users)
  end

  @add_users_role ~w(admin)a
  def upsert_users_and_groups(conn, %{
        "course_id" => course_id,
        "users" => usernames_roles_groups,
        "provider" => provider
      }) do
    %{role: admin_role} = conn.assigns.course_reg
    usernames_roles_groups = usernames_roles_groups |> Enum.map(&to_snake_case_atom_keys/1)

    with {:validate_cap, true} <-
           {:validate_cap,
            Enum.count(CourseRegistrations.get_users(course_id) ++ usernames_roles_groups) <= 1500},
         {:validate_role, true} <- {:validate_role, admin_role in @add_users_role},
         {:validate_provider, true} <-
           {:validate_provider,
            Map.has_key?(Application.get_env(:cadet, :identity_providers, %{}), provider)},
         {:validate_usernames, true} <-
           {:validate_usernames,
            Enum.all?(usernames_roles_groups, fn x ->
              Map.has_key?(x, :username) and is_binary(x.username) and x.username != ""
            end)},
         {:validate_roles, true} <-
           {:validate_roles,
            Enum.all?(usernames_roles_groups, fn x ->
              Map.has_key?(x, :role) and String.to_atom(x.role) in Role.__enums__()
            end)} do
      {:ok, conn} =
        Repo.transaction(
          fn ->
            with {:upsert_users, :ok} <-
                   {:upsert_users,
                    CourseRegistrations.upsert_users_in_course(
                      provider,
                      usernames_roles_groups,
                      course_id
                    )},
                 {:upsert_groups, :ok} <-
                   {:upsert_groups,
                    Courses.upsert_groups_in_course(usernames_roles_groups, course_id, provider)} do
              text(conn, "OK")
            else
              {:upsert_users, {:error, {status, message}}} ->
                conn |> put_status(status) |> text(message)

              {:upsert_groups, {:error, {status, message}}} ->
                conn |> put_status(status) |> text(message)
            end
          end,
          timeout: 20_000
        )

      conn
    else
      {:validate_cap, false} ->
        conn |> put_status(:bad_request) |> text("A course can have maximum of 1500 users")

      {:validate_role, false} ->
        conn |> put_status(:forbidden) |> text("User is not permitted to add users")

      {:validate_provider, false} ->
        conn |> put_status(:bad_request) |> text("Invalid authentication provider")

      {:validate_usernames, false} ->
        conn |> put_status(:bad_request) |> text("Invalid username(s) provided")

      {:validate_roles, false} ->
        conn |> put_status(:bad_request) |> text("Invalid role(s) provided")
    end
  end

  @update_role_roles ~w(admin)a
  def update_role(conn, %{"role" => role, "course_reg_id" => course_reg_id}) do
    course_reg_id = course_reg_id |> String.to_integer()

    %{id: admin_course_reg_id, role: admin_role, course_id: admin_course_id} =
      conn.assigns.course_reg

    with {:validate_role, true} <- {:validate_role, admin_role in @update_role_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != course_reg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^course_reg_id) |> Repo.one()},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id} do
      case CourseRegistrations.update_role(role, course_reg_id) do
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
  def delete_user(conn, %{"course_reg_id" => course_reg_id}) do
    course_reg_id = course_reg_id |> String.to_integer()

    %{id: admin_course_reg_id, role: admin_role, course_id: admin_course_id} =
      conn.assigns.course_reg

    with {:validate_role, true} <- {:validate_role, admin_role in @delete_user_roles},
         {:validate_not_self, true} <- {:validate_not_self, admin_course_reg_id != course_reg_id},
         {:get_cr, user_course_reg} when not is_nil(user_course_reg) <-
           {:get_cr, CourseRegistration |> where(id: ^course_reg_id) |> Repo.one()},
         {:prevent_delete_admin, true} <- {:prevent_delete_admin, user_course_reg.role != :admin},
         {:validate_same_course, true} <-
           {:validate_same_course, user_course_reg.course_id == admin_course_id} do
      case CourseRegistrations.delete_course_registration(course_reg_id) do
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
    get("/courses/{course_id}/admin/users")

    summary("Returns a list of users in the course owned by the admin")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:AdminUserInfo))
    response(401, "Unauthorised")
  end

  swagger_path :combined_total_xp do
    get("/courses/{course_id}/admin/users/{course_reg_id}/total_xp")

    summary("Get the specified user's total XP from achievements and assessments")

    security([%{JWT: []}])
    produces("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      course_reg_id(:path, :integer, "Course registration ID", required: true)
    end

    response(200, "OK", Schema.ref(:TotalXPInfo))
    response(401, "Unauthorised")
  end

  swagger_path :upsert_users_and_groups do
    put("/courses/{course_id}/admin/users")

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
    put("/courses/{course_id}/admin/users/{course_reg_id}/role")

    summary("Updates the role of the given user in the the course")
    security([%{JWT: []}])
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)
      role(:body, :role, "The new role", required: true)

      courseRegId(
        :body,
        :integer,
        "The course registration of the user whose role is to be updated",
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
    delete("/courses/{course_id}/admin/users/{course_reg_id}")

    summary("Deletes a user from a course")
    consumes("application/json")

    parameters do
      course_id(:path, :integer, "Course ID", required: true)

      courseRegId(
        :body,
        :integer,
        "The course registration of the user whose role is to be updated",
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
