defmodule CadetWeb.NewNotificationsController do
  use CadetWeb, :controller

  alias Cadet.{Repo, Notifications}

  alias Cadet.Notifications.{
    NotificationPreference,
    NotificationConfig,
    TimeOption,
    PreferableTime
  }

  # NOTIFICATION CONFIGS

  def all_noti_configs(conn, %{"course_id" => course_id}) do
    configs = Notifications.get_notification_configs(course_id)
    render(conn, "configs_full.json", configs: configs)
  end

  def get_configurable_noti_configs(conn, %{"course_reg_id" => course_reg_id}) do
    configs = Notifications.get_configurable_notification_configs(course_reg_id)

    case configs do
      nil -> conn |> put_status(400) |> text("course_reg_id does not exist")
      _ -> render(conn, "configs_full.json", configs: configs)
    end
  end

  def update_noti_configs(conn, params) do
    changesets =
      params["_json"]
      |> snake_casify_string_keys_recursive()
      |> Stream.map(fn noti_config ->
        config = Repo.get(NotificationConfig, noti_config["id"])
        NotificationConfig.changeset(config, noti_config)
      end)
      |> Enum.to_list()

    case Notifications.update_many_noti_configs(changesets) do
      {:ok, res} ->
        render(conn, "configs_full.json", configs: res)

      {:error, changeset} ->
        conn |> put_status(400) |> text(changeset_error_to_string(changeset))
    end
  end

  # NOTIFICATION PREFERENCES

  def upsert_noti_preferences(conn, params) do
    changesets =
      params["_json"]
      |> snake_casify_string_keys_recursive()
      |> Stream.map(fn noti_pref ->
        if noti_pref["id"] < 0 do
          Map.delete(noti_pref, "id")
        end

        NotificationPreference.changeset(%NotificationPreference{}, noti_pref)
      end)
      |> Enum.to_list()

    case Notifications.upsert_many_noti_preferences(changesets) do
      {:ok, res} ->
        render(conn, "noti_prefs.json", noti_prefs: res)

      {:error, changeset} ->
        conn |> put_status(400) |> text(changeset_error_to_string(changeset))
    end
  end

  # TIME OPTIONS

  def get_config_time_options(conn, %{"noti_config_id" => noti_config_id}) do
    time_options = Notifications.get_time_options_for_config(noti_config_id)

    render(conn, "time_options.json", %{time_options: time_options})
  end

  def upsert_time_options(conn, params) do
    changesets =
      params["_json"]
      |> snake_casify_string_keys_recursive()
      |> Stream.map(fn time_option ->
        if time_option["id"] < 0 do
          Map.delete(time_option, "id")
        end

        TimeOption.changeset(%TimeOption{}, time_option)
      end)
      |> Enum.to_list()

    case Notifications.upsert_many_time_options(changesets) do
      {:ok, res} ->
        render(conn, "time_options.json", time_options: res)

      {:error, changeset} ->
        conn |> put_status(400) |> text(changeset_error_to_string(changeset))
    end
  end

  def delete_time_options(conn, params) do
    case Notifications.delete_many_time_options(params["_json"]) do
      {:ok, res} ->
        render(conn, "time_options.json", time_options: res)

      {:error, message} ->
        conn |> put_status(400) |> text(message)

      {:delete_error, changeset} ->
        conn |> put_status(400) |> text(changeset_error_to_string(changeset))
    end
  end

  def upsert_preferable_times(conn, params) do
    changesets =
      params["_json"]
      |> snake_casify_string_keys_recursive()
      |> Stream.map(fn preferable_time ->
        if preferable_time["id"] < 0 do
          Map.delete(preferable_time, "id")
        end

        PreferableTime.changeset(%PreferableTime{}, preferable_time)
      end)
      |> Enum.to_list()

    case Notifications.upsert_many_preferable_times(changesets) do
      {:ok, res} ->
        render(conn, "preferable_times", preferable_times: res)

      {:error, changeset} ->
        conn |> put_status(400) |> text(changeset_error_to_string(changeset))
    end
  end

  def delete_preferable_times(conn, params) do
    case Notifications.delete_many_preferable_times(params["_json"]) do
      {:ok, res} ->
        render(conn, "preferable_times.json", preferable_times: res)

      {:error, message} ->
        conn |> put_status(400) |> text(message)

      {:delete_error, changeset} ->
        conn |> put_status(400) |> text(changeset_error_to_string(changeset))
    end
  end
end
