defmodule CadetWeb.NotificationConfigView do
  use CadetWeb, :view
  alias CadetWeb.NotificationConfigView

  def render("index.json", %{notification_configs: notification_configs}) do
    %{data: render_many(notification_configs, NotificationConfigView, "notification_config.json")}
  end

  def render("show.json", %{notification_config: notification_config}) do
    %{data: render_one(notification_config, NotificationConfigView, "notification_config.json")}
  end

  def render("notification_config.json", %{notification_config: notification_config}) do
    %{
      id: notification_config.id,
      is_enabled: notification_config.is_enabled
    }
  end
end
