defmodule CadetWeb.NotificationsController do
  @moduledoc """
  Provides information about Notifications.
  """

  use CadetWeb, :controller
  use OpenApiSpex.ControllerSpecs

  plug(OpenApiSpex.Plug.CastAndValidate,
    render_error: CadetWeb.Plugs.OpenApiErrorRenderer,
    replace_params: false
  )

  alias Cadet.Accounts.Notifications
  alias CadetWeb.ApiSpec.ErrorResponses
  alias CadetWeb.Schemas
  alias OpenApiSpex.Schema

  tags(["Notifications"])
  security([%{"JWT" => []}])

  operation(:index,
    summary: "Get the unread notifications belonging to the current user",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    responses: [
      ok:
        {"List of notifications", "application/json",
         %Schema{type: :array, items: Schemas.Notification}},
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden()
    ]
  )

  def index(conn, _) do
    {:ok, notifications} = Notifications.fetch(conn.assigns.course_reg)

    render(
      conn,
      "index.json",
      notifications: notifications
    )
  end

  operation(:acknowledge,
    summary: "Acknowledge one or more notifications",
    parameters: [
      course_id: [in: :path, type: :integer, required: true, description: "Course ID"]
    ],
    request_body:
      {"The notification ids to acknowledge", "application/json",
       Schemas.AcknowledgeNotificationsRequest},
    responses: [
      ok: {"Notifications acknowledged", "text/plain", %Schema{type: :string}},
      bad_request: ErrorResponses.bad_request(),
      unauthorized: ErrorResponses.unauthorised(),
      forbidden: ErrorResponses.forbidden(),
      not_found: ErrorResponses.not_found(),
      internal_server_error: ErrorResponses.internal_server_error()
    ]
  )

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
end
