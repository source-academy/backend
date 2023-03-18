defmodule CadetWeb.NewNotificationsView do
  use CadetWeb, :view

  require IEx

  def render("noti_types.json", %{noti_types: noti_types}) do
    render_many(noti_types, CadetWeb.NewNotificationsView, "noti_type.json", as: :noti_type)
  end

  def render("noti_type.json", %{noti_type: noti_type}) do
    render_notification_type(noti_type)
  end

  def render("configs.json", %{configs: configs}) do
    render_many(configs, CadetWeb.NewNotificationsView, "config.json", as: :config)
  end

  def render("config.json", %{config: config}) do
    transform_map_for_view(config, %{
      id: :id,
      isEnabled: :is_enabled,
      notificationType: &render_notification_type(&1.notification_type),
      assessmentConfig: &render_assessment_config(&1.assessment_config),
      time_options:
        &render_many(
          &1.time_options,
          CadetWeb.NewNotificationsView,
          "time_option.json",
          as: :time_option
        )
    })
  end

  def render("preference.json", %{noti_pref: noti_pref}) do
    transform_map_for_view(noti_pref, %{
      id: :id,
      isEnabled: :is_enabled,
      timeOption: :time_option
    })
  end

  def render("time_options.json", %{time_options: time_options}) do
    render_many(time_options, CadetWeb.NewNotificationsView, "time_option.json", as: :time_option)
  end

  def render("time_option.json", %{time_option: time_option}) do
    transform_map_for_view(time_option, %{
      id: :id,
      minutes: :minutes,
      isDefault: :is_default
    })
  end

  defp render_notification_type(noti_type) do
    case noti_type do
      nil ->
        nil

      _ ->
        transform_map_for_view(noti_type, %{
          id: :id,
          name: :name,
          forStaff: :for_staff,
          isEnabled: :is_enabled
        })
    end
  end

  defp render_assessment_config(ass_config) do
    case ass_config do
      nil ->
        nil

      _ ->
        transform_map_for_view(ass_config, %{
          id: :id,
          type: :type
        })
    end
  end

  defp render_course(course) do
    case course do
      nil ->
        nil

      _ ->
        transform_map_for_view(course, %{
          id: :id,
          courseName: :course_name,
          courseShortName: :course_short_name
        })
    end
  end
end
