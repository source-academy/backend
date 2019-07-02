defmodule CadetWeb.ChatController do
  @moduledoc """
  Provides token for connection to ChatKit's server.
  Refer to ChatKit's API here: https://pusher.com/docs/chatkit
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  import Cadet.Chat.Token

  def index(conn, _) do
    user = conn.assigns.current_user
    {:ok, token, ttl} = get_user_token(user)

    render(
      conn,
      "index.json",
      access_token: token,
      expires_in: ttl
    )
  end

  swagger_path :index do
    post("/chat/token")

    summary("Get the ChatKit bearer token of a user. Token expires in 24 hours.")

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
            access_token(:string, "Bearer token", required: true)

            expires_in(:string, "TTL of token", required: true)
          end
        end
    }
  end
end
