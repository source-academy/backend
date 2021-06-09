defmodule CadetWeb.AdminUserController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Accounts
  # alias Cadet.Accounts.CourseRegistrations

  # :TODO this controller seems to be obsolte in the current version we will use the course_reg controller to find all users of a course

  def index(conn, filter) do
    users = filter |> try_keywordise_string_keys() |> Accounts.get_users_by(conn.assigns.course_reg)

    render(conn, "users.json", users: users)
  end

  swagger_path :index do
    get("/admin/users")

    summary("Returns a list of users in the course owned by the admin")

    security([%{JWT: []}])
    produces("application/json")
    response(200, "OK", Schema.ref(:AdminUserInfo))
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      AdminUserInfo:
        swagger_schema do
          title("User")
          description("Basic information about the users in this course")

          properties do
            userId(:integer, "User's ID")
            name(:string, "Full name of the user")
            role(:string, "Role of the user in this course. Can be 'student', 'staff', or 'admin'")

            group(
              :string,
              "Group the user belongs to in this course. May be null if the user does not belong to any group"
            )
          end
        end
    }
  end
end
