defmodule CadetWeb.NotificationTypeController do
  use CadetWeb, :controller

  alias Cadet.Notifications
  alias Cadet.Notifications.NotificationType

  # action_fallback(CadetWeb.FallbackController)

  def index(conn, _params) do
    notification_types = Notifications.list_notification_types()
    render(conn, "index.json", notification_types: notification_types)
  end

  def create(conn, %{"notification_type" => notification_type_params}) do
    with {:ok, %NotificationType{} = notification_type} <-
           Notifications.create_notification_type(notification_type_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", Routes.notification_type_path(conn, :show, notification_type))
      |> render("show.json", notification_type: notification_type)
    end
  end

  def show(conn, %{"id" => id}) do
    notification_type = Notifications.get_notification_type!(id)
    render(conn, "show.json", notification_type: notification_type)
  end

  def update(conn, %{"id" => id, "notification_type" => notification_type_params}) do
    notification_type = Notifications.get_notification_type!(id)

    with {:ok, %NotificationType{} = notification_type} <-
           Notifications.update_notification_type(notification_type, notification_type_params) do
      render(conn, "show.json", notification_type: notification_type)
    end
  end

  def delete(conn, %{"id" => id}) do
    notification_type = Notifications.get_notification_type!(id)

    with {:ok, %NotificationType{}} <- Notifications.delete_notification_type(notification_type) do
      send_resp(conn, :no_content, "")
    end
  end
end
