defmodule CadetWeb.NotificationConfigController do
  use CadetWeb, :controller

  alias Cadet.Notifications
  alias Cadet.Notifications.NotificationConfig

  action_fallback(CadetWeb.FallbackController)

  def index(conn, _params) do
    notification_configs = Notifications.list_notification_configs()
    render(conn, "index.json", notification_configs: notification_configs)
  end

  def create(conn, %{"notification_config" => notification_config_params}) do
    with {:ok, %NotificationConfig{} = notification_config} <-
           Notifications.create_notification_config(notification_config_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", Routes.notification_config_path(conn, :show, notification_config))
      |> render("show.json", notification_config: notification_config)
    end
  end

  def show(conn, %{"id" => id}) do
    notification_config = Notifications.get_notification_config!(id)
    render(conn, "show.json", notification_config: notification_config)
  end

  def update(conn, %{"id" => id, "notification_config" => notification_config_params}) do
    notification_config = Notifications.get_notification_config!(id)

    with {:ok, %NotificationConfig{} = notification_config} <-
           Notifications.update_notification_config(
             notification_config,
             notification_config_params
           ) do
      render(conn, "show.json", notification_config: notification_config)
    end
  end

  def delete(conn, %{"id" => id}) do
    notification_config = Notifications.get_notification_config!(id)

    with {:ok, %NotificationConfig{}} <-
           Notifications.delete_notification_config(notification_config) do
      send_resp(conn, :no_content, "")
    end
  end
end
