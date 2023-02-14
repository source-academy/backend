defmodule CadetWeb.SentNotificationController do
  use CadetWeb, :controller

  alias Cadet.Notifications
  alias Cadet.Notifications.SentNotification

  # action_fallback CadetWeb.FallbackController

  def index(conn, _params) do
    sent_notifications = Notifications.list_sent_notifications()
    render(conn, "index.json", sent_notifications: sent_notifications)
  end

  def create(conn, %{"sent_notification" => sent_notification_params}) do
    with {:ok, %SentNotification{} = sent_notification} <-
           Notifications.create_sent_notification(sent_notification_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", Routes.sent_notification_path(conn, :show, sent_notification))
      |> render("show.json", sent_notification: sent_notification)
    end
  end

  def show(conn, %{"id" => id}) do
    sent_notification = Notifications.get_sent_notification!(id)
    render(conn, "show.json", sent_notification: sent_notification)
  end

  def update(conn, %{"id" => id, "sent_notification" => sent_notification_params}) do
    sent_notification = Notifications.get_sent_notification!(id)

    with {:ok, %SentNotification{} = sent_notification} <-
           Notifications.update_sent_notification(sent_notification, sent_notification_params) do
      render(conn, "show.json", sent_notification: sent_notification)
    end
  end

  def delete(conn, %{"id" => id}) do
    sent_notification = Notifications.get_sent_notification!(id)

    with {:ok, %SentNotification{}} <- Notifications.delete_sent_notification(sent_notification) do
      send_resp(conn, :no_content, "")
    end
  end
end
