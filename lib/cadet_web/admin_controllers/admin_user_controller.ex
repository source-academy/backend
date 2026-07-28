defmodule CadetWeb.AdminUserController do
  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.{Accounts, Assessments, Courses}
  alias Cadet.Accounts.{CourseRegistrations, CourseRegistration, Role}
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["User"])
  security([%{"JWT" => []}])

  # This controller is used to find all users of a course

  operation(:index,
    summary: "Get all users in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of users", "application/json", %Schema{type: :array, items: Schemas.AdminUserInfo}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, filter) do
    users =
      filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "users.json", users: users)
  end

  operation(:combined_total_xp,
    summary: "Get a specific user's total XP from achievements and assessments",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      course_reg_id: [in: :path, type: :integer, required: true, description: "Course reg ID"]
    ],
    responses: [
      ok: {"Total XP", "application/json", Schemas.TotalXP},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def combined_total_xp(conn, %{"course_reg_id" => course_reg_id}) do
    course_reg = Repo.get(CourseRegistration, course_reg_id)

    course_id = course_reg.course_id
    user_id = course_reg.user_id
    course_reg_id = course_reg.id

    total_xp = Assessments.user_total_xp(course_id, user_id, course_reg_id)
    json(conn, %{totalXp: total_xp})
  end

  @add_users_role ~w(admin)a

  operation(:get_students,
    summary: "Get the students in the course (for team formation)",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of students", "application/json",
         %Schema{type: :array, items: %Schema{type: :object}}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def get_students(conn, filter) do
    users =
      filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "get_students.json", users: users)
  end

  operation(:upsert_users_and_groups,
    summary: "Add or update users (and their groups) in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body: {"The users to upsert", "application/json", Schemas.UpsertUsersRequest},
    responses: [
      ok: {"Users upserted", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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

  operation(:update_role,
    summary: "Update the role of a user in the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      course_reg_id: [in: :path, type: :integer, required: true, description: "Course reg ID"]
    ],
    request_body: {"The new role", "application/json", Schemas.UpdateRoleRequest},
    responses: [
      ok: {"Role updated", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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

  operation(:delete_user,
    summary: "Delete a user from the course",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"],
      course_reg_id: [in: :path, type: :integer, required: true, description: "Course reg ID"]
    ],
    responses: [
      ok: {"User deleted", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

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
end
