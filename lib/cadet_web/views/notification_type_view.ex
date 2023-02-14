defmodule CadetWeb.NotificationTypeView do
  use CadetWeb, :view
  alias CadetWeb.NotificationTypeView

  def render("index.json", %{notification_types: notification_types}) do
    %{data: render_many(notification_types, NotificationTypeView, "notification_type.json")}
  end

  def render("show.json", %{notification_type: notification_type}) do
    %{data: render_one(notification_type, NotificationTypeView, "notification_type.json")}
  end

  def render("notification_type.json", %{notification_type: notification_type}) do
    %{
      id: notification_type.id,
      name: notification_type.name,
      template_file_name: notification_type.template_file_name,
      is_enabled: notification_type.is_enabled,
      is_autopopulated: notification_type.is_autopopulated
    }
  end
end
