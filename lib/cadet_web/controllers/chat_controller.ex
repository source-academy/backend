defmodule CadetWeb.ChatController do
  @moduledoc """
  Provides token for connection to ChatKit's server.
  Refer to ChatKit's API here: https://pusher.com/docs/chatkit
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Chat.Token
  alias Cadet.Accounts.Notifications

  def index(conn, _) do
    user = conn.assigns.current_user
    {:ok, token, ttl} = Token.get_user_token(user)

    render(
      conn,
      "index.json",
      access_token: token,
      expires_in: ttl
    )
  end

  def notify(conn, params = %{}) do
    user = conn.assigns.current_user

    result =
      case user.role do
        :student ->
          Notifications.write_notification_for_chatkit_avenger(user, params["assessmentId"])

        :staff ->
          Notifications.write_notification_for_chatkit_student(user, params["submissionId"])

        _ ->
          {:error, {:bad_request, "Invalid Role"}}
      end

    case result do
      {:ok, _} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)

      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> text("Internal server error")
    end
  end

  swagger_path :index do
    post("/chat/token")

    summary("Get the ChatKit bearer token of a user. Token expires in 24 hours.")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:TokenInfo))
  end

  swagger_path :notify do
    post("/chat/notify")

    summary("Notify participating users about new messages.")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      ids(:body, Schema.ref(:NotifyIds), "The ids to specify the notification location with.")
    end

    response(200, "OK")
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
        end,
      NotifyIds:
        swagger_schema do
          properties do
            assessmentId(:integer, "assessment id (if any)")
            submissionId(:integer, "submission id (if any)")
          end
        end
    }
  end
end
