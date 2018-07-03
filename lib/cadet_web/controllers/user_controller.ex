defmodule CadetWeb.UserController do
  @moduledoc """
  Provides information about a user.
  """
  use CadetWeb, :controller

  use PhoenixSwagger

  swagger_path :index do
    get("/user")

    summary("Get the name and role of a user")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      access_token(
        :body,
        Schema.ref(:AccessToken),
        "access token obtained from /auth",
        required: true
      )
    end

    response(200, "OK", Schema.ref(:UserInfo))
    response(400, "Missing parameter")
    response(401, "Invalid access token")
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
          end
        end
    }
  end
end
