defmodule CadetWeb.NewNotificationsController do
  use CadetWeb, :controller

  alias Cadet.Repo
  alias Cadet.Notifications
  alias Cadet.Notifications.{NotificationPreference, TimeOption}

  # NOTIFICATION CONFIGS

  def all_noti_configs(conn, %{"course_id" => course_id}) do
    configs = Notifications.get_notification_configs(course_id)
    render(conn, "configs.json", configs: configs)
  end

  def get_configurable_noti_configs(conn, %{"course_reg_id" => course_reg_id}) do
    configs = Notifications.get_configurable_notification_configs(course_reg_id)
    render(conn, "configs.json", configs: configs)
  end

  # NOTIFICATION PREFERENCES

  def create_preference(conn, params) do
    changeset = NotificationPreference.changeset(%NotificationPreference{}, params)

    case Repo.insert(changeset) do
      {:ok, res} ->
        pref = Notifications.get_notification_preference!(res.id)
        render(conn, "noti_pref.json", noti_pref: pref)

      {:error, {status, message}} ->
        conn |> put_status(status) |> text(message)
    end
  end

  def update_preference(conn, %{
        "noti_pref_id" => id,
        "is_enabled" => is_enabled,
        "time_option_id" => time_option_id
      }) do
    pref = Repo.get(NotificationPreference, id)

    if is_nil(pref) do
      conn |> put_status(404) |> text("Notification preference of given ID not found")
    end

    changeset =
      pref
      |> NotificationPreference.changeset(%{is_enabled: is_enabled})
      |> NotificationPreference.changeset(%{time_option_id: time_option_id})

    case Repo.update(changeset) do
      {:ok, res} ->
        pref = Notifications.get_notification_preference!(res.id)
        render(conn, "noti_pref.json", noti_pref: pref)

      {:error, {status, message}} ->
        conn |> put_status(status) |> text(message)
    end
  end

  # TIME OPTIONS

  def get_config_time_options(conn, %{"noti_config_id" => noti_config_id}) do
    time_options = Notifications.get_time_options_for_config(noti_config_id)

    render(conn, "time_options.json", %{time_options: time_options})
  end

  def create_time_option(conn, params) do
    changeset = TimeOption.changeset(%TimeOption{}, params)

    case Repo.insert(changeset) do
      {:ok, res} ->
        render(conn, "time_option.json", time_option: res)

      {:error, {status, message}} ->
        conn |> put_status(status) |> text(message)
    end
  end

  # Only allow updating of `is_default`
  # should delete and create a new entry for other fields
  def update_time_option(conn, %{"time_option_id" => time_option_id, "is_default" => is_default}) do
    time_option = Repo.get(TimeOption, time_option_id)

    if is_nil(time_option) do
      conn |> put_status(404) |> text("Time option of given ID not found")
    end

    changeset =
      time_option
      |> TimeOption.changeset(%{is_default: is_default})

    case Repo.update(changeset) do
      {:ok, res} ->
        render(conn, "time_option.json", time_option: res)

      {:error, {status, message}} ->
        conn |> put_status(status) |> text(message)
    end
  end

  def delete_time_option(conn, %{"time_option_id" => time_option_id}) do
    time_option = Repo.get(TimeOption, time_option_id)

    if is_nil(time_option) do
      conn |> put_status(404) |> text("Time option of given ID not found")
    end

    case Repo.delete(time_option) do
      {:ok, res} ->
        render(conn, "time_option.json", time_option: res)

      {:error, {status, message}} ->
        conn |> put_status(status) |> text(message)
    end
  end
end
