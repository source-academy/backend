defmodule CadetWeb.NotificationsController do
  @moduledoc """
  Provides information about Notifications.
  """

  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Accounts.Notifications

  def index(conn, _) do
    {:ok, notifications} = Notifications.fetch(conn.assigns.course_reg)

    render(
      conn,
      "index.json",
      notifications: notifications
    )
  end

  def acknowledge(conn, %{"notificationIds" => notification_ids}) do
    case Notifications.acknowledge(
           notification_ids,
           conn.assigns.course_reg
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
    get("/courses/{course_id}/notifications")

    summary("Get the unread notifications belonging to a user")

    security([%{JWT: []}])

    produces("application/json")

    response(200, "OK", Schema.array(:Notification))
    response(401, "Unauthorised")
  end

  swagger_path :acknowledge do
    post("/courses/{course_id}/notifications/acknowledge")
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
      Notification:
        swagger_schema do
          title("Notification")
          description("Information about a single notification")

          properties do
            id(:integer, "the notification id", required: true)
            type(Schema.ref(:NotificationType), "the type of the notification", required: true)
            read(:boolean, "the read status of the notification", required: true)

            submission_id(:integer, "the submission id the notification references",
              required: true
            )

            question_id(:integer, "the question id the notification references")

            assessment_id(:integer, "the assessment id the notification references")
            assessment(Schema.ref(:AssessmentInfo), "the assessment the notification references")
          end
        end,
      NotificationIds:
        swagger_schema do
          properties do
            notificationIds(Schema.array(:integer), "the notification ids")
          end
        end,
      NotificationType:
        swagger_schema do
          type(:string)

          enum([
            :new,
            :submitted,
            :unsubmitted,
            :unpublished_grading,
            :published_grading,
            :new_message
          ])
        end
    }
  end
end
