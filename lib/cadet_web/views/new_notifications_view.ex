defmodule CadetWeb.NewNotificationsView do
  use CadetWeb, :view

  require IEx

  # Notification Type
  def render("noti_types.json", %{noti_types: noti_types}) do
    render_many(noti_types, CadetWeb.NewNotificationsView, "noti_type.json", as: :noti_type)
  end

  def render("noti_type.json", %{noti_type: noti_type}) do
    render_notification_type(noti_type)
  end

  # Notification Config
  def render("configs_full.json", %{configs: configs}) do
    render_many(configs, CadetWeb.NewNotificationsView, "config_full.json", as: :config)
  end

  def render("config_full.json", %{config: config}) do
    transform_map_for_view(config, %{
      id: :id,
      isEnabled: :is_enabled,
      course: &render_course(&1.course),
      notificationType: &render_notification_type(&1.notification_type),
      assessmentConfig: &render_assessment_config(&1.assessment_config),
      notificationPreference: &render_first_notification_preferences(&1.notification_preferences),
      timeOptions:
        &render(
          "time_options.json",
          %{time_options: &1.time_options}
        )
    })
  end

  def render("config.json", %{config: config}) do
    transform_map_for_view(config, %{
      id: :id,
      isEnabled: :is_enabled
    })
  end

  # Notification Preference
  def render("noti_pref.json", %{noti_pref: noti_pref}) do
    transform_map_for_view(noti_pref, %{
      id: :id,
      isEnabled: :is_enabled,
      timeOptionId: :time_option_id
    })
  end

  # Time Options
  def render("time_options.json", %{time_options: time_options}) do
    case time_options do
      %Ecto.Association.NotLoaded{} ->
        nil
      _ ->
        render_many(time_options, CadetWeb.NewNotificationsView, "time_option.json", as: :time_option)
    end
  end

  def render("time_option.json", %{time_option: time_option}) do
    transform_map_for_view(time_option, %{
      id: :id,
      minutes: :minutes,
      isDefault: :is_default
    })
  end

  # Helpers
  defp render_notification_type(noti_type) do
    case noti_type do
      nil ->
        nil

      %Ecto.Association.NotLoaded{} ->
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

  # query returns an array but there should be max 1 result
  defp render_first_notification_preferences(noti_prefs) do
    case noti_prefs do
      nil ->
        nil

      %Ecto.Association.NotLoaded{} ->
        nil

      _ ->
        if Enum.empty?(noti_prefs) do
          nil
        else
          render("noti_pref.json", %{noti_pref: Enum.at(noti_prefs, 0)})
        end
    end
  end

  defp render_assessment_config(ass_config) do
    case ass_config do
      nil ->
        nil

      %Ecto.Association.NotLoaded{} ->
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

      %Ecto.Association.NotLoaded{} ->
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
