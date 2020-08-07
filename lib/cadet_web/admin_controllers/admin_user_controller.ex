defmodule CadetWeb.AdminUserController do
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Accounts

  def index(conn, filter) do
    users = filter |> try_keywordise_string_keys() |> Accounts.get_users()

    render(conn, "users.json", users: users)
  end

  swagger_path :index do
    get("/admin/users")

    summary("Returns a list of users")

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
          description("Basic information about the user")

          properties do
            userId(:integer, "User's ID")
            name(:string, "Full name of the user")
            role(:string, "Role of the user. Can be 'student', 'staff', or 'admin'")

            group(
              :string,
              "Group the user belongs to. May be null if the user does not belong to any group."
            )
          end
        end
    }
  end
end
