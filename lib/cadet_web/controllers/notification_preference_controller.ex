defmodule CadetWeb.NotificationPreferenceController do
  use CadetWeb, :controller

  alias Cadet.Notifications
  alias Cadet.Notifications.NotificationPreference

  # action_fallback CadetWeb.FallbackController

  def index(conn, _params) do
    notification_preferences = Notifications.list_notification_preferences()
    render(conn, "index.json", notification_preferences: notification_preferences)
  end

  def create(conn, %{"notification_preference" => notification_preference_params}) do
    with {:ok, %NotificationPreference{} = notification_preference} <-
           Notifications.create_notification_preference(notification_preference_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header(
      #   "location",
      #   Routes.notification_preference_path(conn, :show, notification_preference
      # ))
      |> render("show.json", notification_preference: notification_preference)
    end
  end

  def show(conn, %{"id" => id}) do
    notification_preference = Notifications.get_notification_preference!(id)
    render(conn, "show.json", notification_preference: notification_preference)
  end

  def update(conn, %{"id" => id, "notification_preference" => notification_preference_params}) do
    notification_preference = Notifications.get_notification_preference!(id)

    with {:ok, %NotificationPreference{} = notification_preference} <-
           Notifications.update_notification_preference(
             notification_preference,
             notification_preference_params
           ) do
      render(conn, "show.json", notification_preference: notification_preference)
    end
  end

  def delete(conn, %{"id" => id}) do
    notification_preference = Notifications.get_notification_preference!(id)

    with {:ok, %NotificationPreference{}} <-
           Notifications.delete_notification_preference(notification_preference) do
      send_resp(conn, :no_content, "")
    end
  end
end
