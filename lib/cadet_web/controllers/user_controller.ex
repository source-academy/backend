defmodule CadetWeb.UserController do
  @moduledoc """
  Provides information about a user.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  import Cadet.Assessments

  def index(conn, _) do
    user = conn.assigns.current_user
    xp = user_total_xp(user)
    render(conn, "index.json", user: user, xp: xp)
  end

  swagger_path :index do
    get("/user")

    summary("Get the name and role of a user")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:UserInfo))
    response(401, "Unauthorised")
  end

  def swagger_definitions do
    %{
      UserInfo:
        swagger_schema do
          title("User")
          description("Basic information about the user")

          properties do
            name(:string, "Full name of the user", required: true)

            role(
              :string,
              "Role of the user. Can be 'Student', 'Staff', or 'Admin'",
              required: true
            )

            xp(:integer, "Amount of XP. Only provided for 'Student'")
          end
        end
    }
  end
end
