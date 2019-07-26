defmodule CadetWeb.NotificationView do
  use CadetWeb, :view

  def render("index.json", %{notifications: notifications}) do
    render_many(notifications, CadetWeb.NotificationView, "notification.json")
  end

  def render("notification.json", %{notification: notification}) do
    transform_map_for_view(notification, %{
      id: :id,
      type: :type,
      assessment_id: :assessment_id,
      submission_id: :submission_id,
      assessment:
        &transform_map_for_view(&1.assessment, %{
          type: :type,
          title: :title
        })
    })
  end
end
