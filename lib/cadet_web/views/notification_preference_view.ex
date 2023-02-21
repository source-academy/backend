defmodule CadetWeb.NotificationPreferenceView do
  use CadetWeb, :view
  alias CadetWeb.NotificationPreferenceView

  def render("index.json", %{notification_preferences: notification_preferences}) do
    %{
      data:
        render_many(
          notification_preferences,
          NotificationPreferenceView,
          "notification_preference.json"
        )
    }
  end

  def render("show.json", %{notification_preference: notification_preference}) do
    %{
      data:
        render_one(
          notification_preference,
          NotificationPreferenceView,
          "notification_preference.json"
        )
    }
  end

  def render("notification_preference.json", %{notification_preference: notification_preference}) do
    %{
      id: notification_preference.id,
      is_enabled: notification_preference.is_enabled
    }
  end
end
