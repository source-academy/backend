defmodule CadetWeb.NotificationController do
  @moduledoc """
  Provides information about a Notifications.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Accounts.Notifications

  def index(conn, _) do
    # TODO
    {:ok, notifications} = Notifications.fetch(conn.assigns.current_user)

    render(
      conn,
      "index.json",
      notifications: notifications
    )
  end

  def acknowledge(conn, %{"notificationId" => notification_id})
      when is_ecto_id(notification_id) do
    case Notifications.acknowledge(
           notification_id,
           conn.assigns.current_user
         ) do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)

      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> text("Please try again later")
    end
  end

  swagger_path :index do
    get("/notification")

    summary("Get the unread notifications belonging to a user")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:Notification))
    response(401, "Unauthorised")
  end

  swagger_path :acknowledge do
    post("/notification/{notificationId}/acknowledge")
    summary("Acknowledge a notification")
    security([%{JWT: []}])

    parameters do
      notificationId(:path, :integer, "notification id", required: true)
    end

    response(200, "OK")
    response(400, "Invalid parameters")
    response(401, "Unauthorised")
    response(404, "Notification does not exist or does not belong to
    user")
  end

  def swagger_definitions do
    %{
      NotificationList:
        swagger_schema do
          description("A list of all notifications")
          type(:array)
          items(Schema.ref(:Notification))
        end,
      Notification:
        swagger_schema do
          title("Notification")
          description("Information about the notification")

          properties do
            id(:integer, "the notification id", required: true)
            type(:string, "the type of the notification", required: true)
            read(:boolean, "the read status of the notification", required: true)

            assessmentId(:integer, "the submission id the notification references", required: true)

            questionId(:integer, "the question id the notification references")
          end
        end
    }
  end
end
