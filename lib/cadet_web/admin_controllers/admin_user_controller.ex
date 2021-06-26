defmodule CadetWeb.AdminUserController do
  use CadetWeb, :controller
  use PhoenixSwagger

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts
  alias Cadet.Accounts.{CourseRegistrations, CourseRegistration}

  # This controller is used to find all users of a course

  def index(conn, filter) do
    users =
      filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "users.json", users: users)
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
        end
    }
  end
end
