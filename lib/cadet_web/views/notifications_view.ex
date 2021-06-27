defmodule CadetWeb.NotificationsView do
  use CadetWeb, :view

  def render("index.json", %{notifications: notifications}) do
    render_many(notifications, CadetWeb.NotificationsView, "notification.json")
  end

  def render("notification.json", %{notifications: notifications}) do
    transform_map_for_view(notifications, %{
      id: :id,
      type: :type,
      assessment_id: :assessment_id,
      submission_id: :submission_id,
      assessment: &render_notification_assessment/1
    })
  end

  defp render_notification_assessment(notification) do
    transform_map_for_view(notification.assessment, %{
      type: & &1.config.type,
      title: :title
    })
  end
end
