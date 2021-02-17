defmodule CadetWeb.NotificationsController do
  @moduledoc """
  Provides information about Notifications.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Accounts.Notifications

  def index(conn, _) do
    {:ok, notifications} = Notifications.fetch(conn.assigns.current_user)

    render(
      conn,
      "index.json",
      notifications: notifications
    )
  end

  def acknowledge(conn, %{"notificationIds" => notification_ids}) do
    case Notifications.acknowledge(
           notification_ids,
           conn.assigns.current_user
         ) do
      {:ok, _nil} ->
        text(conn, "OK")

      {:error, _, {status, message}, _} ->
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
    get("/notifications")

    summary("Get the unread notifications belonging to a user")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.ref(:Notification))
    response(401, "Unauthorised")
  end

  swagger_path :acknowledge do
    post("/notifications/acknowledge")
    summary("Acknowledge notification(s)")
    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      notificationIds(:body, Schema.ref(:NotificationIds), "notification ids", required: true)
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
          description("Information about a single notification")

          properties do
            id(:integer, "the notification id", required: true)
            type(:string, "the type of the notification", required: true)
            read(:boolean, "the read status of the notification", required: true)

            assessmentId(:integer, "the submission id the notification references", required: true)

            questionId(:integer, "the question id the notification references")

            assessment(Schema.ref(:AssessmentInfo))
          end
        end,
      NotificationIds:
        swagger_schema do
          properties do
            notificationIds(Schema.array(:integer), "the notification ids")
          end
        end
    }
  end
end
