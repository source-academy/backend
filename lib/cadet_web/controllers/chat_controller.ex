defmodule CadetWeb.ChatController do
  @moduledoc """
  Provides information about a user.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  import Cadet.Chat

  def index(conn, _) do
    user = conn.assigns.current_user
    {:ok, token} = get_token(user.nusnet_id)

    render(
      conn,
      "index.json",
      token: token
    )
  end

  swagger_path :index do
    get("/chat/token")

    summary("Get the ChatKit bearer token of a user")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:TokenInfo))
  end

  def swagger_definitions do
    %{
      TokenInfo:
        swagger_schema do
          title("ChatKit Token")
          description("Token used for connection to ChatKit's server")

          properties do
            token(:string, "Bearer token", required: true)
          end
        end
    }
  end
end
