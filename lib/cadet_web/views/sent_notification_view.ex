defmodule CadetWeb.SentNotificationView do
  use CadetWeb, :view
  alias CadetWeb.SentNotificationView

  def render("index.json", %{sent_notifications: sent_notifications}) do
    %{data: render_many(sent_notifications, SentNotificationView, "sent_notification.json")}
  end

  def render("show.json", %{sent_notification: sent_notification}) do
    %{data: render_one(sent_notification, SentNotificationView, "sent_notification.json")}
  end

  def render("sent_notification.json", %{sent_notification: sent_notification}) do
    %{
      id: sent_notification.id,
      content: sent_notification.content
    }
  end
end
