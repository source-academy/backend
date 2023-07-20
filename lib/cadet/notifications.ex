defmodule Cadet.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Cadet.Repo

  alias Cadet.Notifications.{
    NotificationType,
    NotificationConfig,
    SentNotification,
    TimeOption,
    NotificationPreference,
    PreferableTime
  }

  @doc """
  Gets a single notification_type.

  Raises `Ecto.NoResultsError` if the Notification type does not exist.

  ## Examples

      iex> get_notification_type!(123)
      %NotificationType{}

      iex> get_notification_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification_type!(id), do: Repo.get!(NotificationType, id)

  @doc """
  Gets a single notification_type by name.any()

  Raises `Ecto.NoResultsError` if the Notification type does not exist.

  ## Examples

      iex> get_notification_type_by_name!("AVENGER BACKLOG")
      %NotificationType{}

      iex> get_notification_type_by_name!("AVENGER BACKLOG")
      ** (Ecto.NoResultsError)
  """
  def get_notification_type_by_name!(name) do
    Repo.one!(from(nt in NotificationType, where: nt.name == ^name))
  end

  def get_notification_config!(notification_type_id, course_id, assconfig_id) do
    query =
      Cadet.Notifications.NotificationConfig
      |> join(:inner, [n], ntype in Cadet.Notifications.NotificationType,
        on: n.notification_type_id == ntype.id
      )
      |> where([n], n.notification_type_id == ^notification_type_id and n.course_id == ^course_id)
      |> filter_assconfig_id(assconfig_id)
      |> Repo.one()

    case query do
      nil ->
        Logger.error(
          "No NotificationConfig found for Course #{course_id} and NotificationType #{notification_type_id}"
        )

        nil

      config ->
        config
    end
  end

  defp filter_assconfig_id(query, nil) do
    query |> where([c], is_nil(c.assessment_config_id))
  end

  defp filter_assconfig_id(query, assconfig_id) do
    query |> where([c], c.assessment_config_id == ^assconfig_id)
  end

  def get_notification_config!(id), do: Repo.get!(NotificationConfig, id)

  @doc """
  Gets all notification configs that belong to a course
  """
  def get_notification_configs(course_id) do
    query =
      Cadet.Notifications.NotificationConfig
      |> where([n], n.course_id == ^course_id)
      |> Repo.all()

    query
    |> Repo.preload([:notification_type, :course, :assessment_config, :time_options])
  end

  @doc """
  Gets all notification configs with preferences that
  1. belongs to the course of the course reg,
  2. only notifications that it can configure based on course reg's role
  """
  def get_configurable_notification_configs(cr_id) do
    cr = Repo.get(Cadet.Accounts.CourseRegistration, cr_id)

    case cr do
      nil ->
        nil

      _ ->
        is_staff = cr.role == :staff

        query =
          Cadet.Notifications.NotificationConfig
          |> join(:inner, [n], ntype in Cadet.Notifications.NotificationType,
            on: n.notification_type_id == ntype.id
          )
          |> join(:inner, [n], c in Cadet.Courses.Course, on: n.course_id == c.id)
          |> join(:left, [n], ac in Cadet.Courses.AssessmentConfig,
            on: n.assessment_config_id == ac.id
          )
          |> join(:left, [n], p in Cadet.Notifications.NotificationPreference,
            on: p.notification_config_id == n.id
          )
          |> where(
            [n, ntype, c, ac, p],
            ntype.for_staff == ^is_staff and
              n.course_id == ^cr.course_id and
              (p.course_reg_id == ^cr.id or is_nil(p.course_reg_id))
          )
          |> Repo.all()

        query
        |> Repo.preload([
          :notification_type,
          :course,
          :assessment_config,
          :time_options,
          :notification_preferences
        ])
    end
  end

  @doc """
  Updates a notification_config.

  ## Examples

      iex> update_notification_config(notification_config, %{field: new_value})
      {:ok, %NotificationConfig{}}

      iex> update_notification_config(notification_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification_config(notification_config = %NotificationConfig{}, attrs) do
    notification_config
    |> NotificationConfig.changeset(attrs)
    |> Repo.update()
  end

  def update_many_noti_configs(noti_configs) when is_list(noti_configs) do
    Repo.transaction(fn ->
      for noti_config <- noti_configs do
        case Repo.update(noti_config) do
          {:ok, res} -> res
          {:error, error} -> Repo.rollback(error)
        end
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification_config changes.

  ## Examples

      iex> change_notification_config(notification_config)
      %Ecto.Changeset{data: %NotificationConfig{}}

  """
  def change_notification_config(notification_config = %NotificationConfig{}, attrs \\ %{}) do
    NotificationConfig.changeset(notification_config, attrs)
  end

  @doc """
  Gets a single time_option.

  Raises `Ecto.NoResultsError` if the Time option does not exist.

  ## Examples

      iex> get_time_option!(123)
      %TimeOption{}

      iex> get_time_option!(456)
      ** (Ecto.NoResultsError)

  """
  def get_time_option!(id), do: Repo.get!(TimeOption, id)

  @doc """
  Gets all time options for a notification config
  """
  def get_time_options_for_config(notification_config_id) do
    query =
      Cadet.Notifications.TimeOption
      |> join(:inner, [to], nc in Cadet.Notifications.NotificationConfig,
        on: to.notification_config_id == nc.id
      )
      |> where([to, nc], nc.id == ^notification_config_id)
      |> Repo.all()

    query
  end

  @doc """
  Gets all time options for an assessment config and notification type
  """
  def get_time_options_for_assessment(assessment_config_id, notification_type_id) do
    query =
      from(ac in Cadet.Courses.AssessmentConfig,
        join: n in Cadet.Notifications.NotificationConfig,
        on: n.assessment_config_id == ac.id,
        join: to in Cadet.Notifications.TimeOption,
        on: to.notification_config_id == n.id,
        where: ac.id == ^assessment_config_id and n.notification_type_id == ^notification_type_id,
        select: to
      )

    Repo.all(query)
  end

  @doc """
  Gets the default time options for an assessment config and notification type
  """
  def get_default_time_option_for_assessment!(assessment_config_id, notification_type_id) do
    query =
      from(ac in Cadet.Courses.AssessmentConfig,
        join: n in Cadet.Notifications.NotificationConfig,
        on: n.assessment_config_id == ac.id,
        join: to in Cadet.Notifications.TimeOption,
        on: to.notification_config_id == n.id,
        where:
          ac.id == ^assessment_config_id and n.notification_type_id == ^notification_type_id and
            to.is_default == true,
        select: to
      )

    Repo.one!(query)
  end

  @doc """
  Creates a time_option.

  ## Examples

      iex> create_time_option(%{field: value})
      {:ok, %TimeOption{}}

      iex> create_time_option(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_time_option(attrs \\ %{}) do
    %TimeOption{}
    |> TimeOption.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_many_time_options(time_options) when is_list(time_options) do
    Repo.transaction(fn ->
      for to <- time_options do
        case Repo.insert(to,
               on_conflict: {:replace, [:is_default]},
               conflict_target: [:minutes, :notification_config_id]
             ) do
          {:ok, time_option} -> time_option
          {:error, error} -> Repo.rollback(error)
        end
      end
    end)
  end

  def upsert_many_noti_preferences(noti_prefs) when is_list(noti_prefs) do
    Repo.transaction(fn ->
      for np <- noti_prefs do
        case Repo.insert(np,
               on_conflict: {:replace, [:is_enabled, :time_option_id]},
               conflict_target: [:course_reg_id, :notification_config_id]
             ) do
          {:ok, noti_pref} -> noti_pref
          {:error, error} -> Repo.rollback(error)
        end
      end
    end)
  end

  @doc """
  Deletes a time_option.

  ## Examples

      iex> delete_time_option(time_option)
      {:ok, %TimeOption{}}

      iex> delete_time_option(time_option)
      {:error, %Ecto.Changeset{}}

  """
  def delete_time_option(time_option = %TimeOption{}) do
    Repo.delete(time_option)
  end

  def delete_many_time_options(to_ids) when is_list(to_ids) do
    Repo.transaction(fn ->
      for to_id <- to_ids do
        time_option = Repo.get(TimeOption, to_id)

        case time_option do
          nil ->
            Repo.rollback("Time option does not exist")

          _ ->
            case Repo.delete(time_option) do
              {:ok, deleted_time_option} -> deleted_time_option
              {:delete_error, error} -> Repo.rollback(error)
            end
        end
      end
    end)
  end

  @doc """
  Gets the notification preference based from its id
  """
  def get_notification_preference!(notification_preference_id) do
    query =
      NotificationPreference
      |> join(:left, [np], to in TimeOption, on: to.id == np.time_option_id)
      |> where([np, to], np.id == ^notification_preference_id)
      |> preload(:time_option)
      |> Repo.one!()

    query
  end

  @doc """
  Gets the notification preference based from notification type and course reg
  """
  def get_notification_preference(notification_type_id, course_reg_id) do
    query =
      from(np in NotificationPreference,
        join: noti in Cadet.Notifications.NotificationConfig,
        on: np.notification_config_id == noti.id,
        join: ntype in NotificationType,
        on: noti.notification_type_id == ntype.id,
        where: ntype.id == ^notification_type_id and np.course_reg_id == ^course_reg_id,
        preload: :time_option
      )

    Repo.one(query)
  end

  @doc """
  Creates a notification_preference.

  ## Examples

      iex> create_notification_preference(%{field: value})
      {:ok, %NotificationPreference{}}

      iex> create_notification_preference(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification_preference(attrs \\ %{}) do
    %NotificationPreference{}
    |> NotificationPreference.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notification_preference.

  ## Examples

      iex> update_notification_preference(notification_preference, %{field: new_value})
      {:ok, %NotificationPreference{}}

      iex> update_notification_preference(notification_preference, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification_preference(notification_preference = %NotificationPreference{}, attrs) do
    notification_preference
    |> NotificationPreference.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notification_preference.

  ## Examples

      iex> delete_notification_preference(notification_preference)
      {:ok, %NotificationPreference{}}

      iex> delete_notification_preference(notification_preference)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification_preference(notification_preference = %NotificationPreference{}) do
    Repo.delete(notification_preference)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification_preference changes.

  ## Examples

      iex> change_notification_preference(notification_preference)
      %Ecto.Changeset{data: %NotificationPreference{}}

  """
  def change_notification_preference(
        notification_preference = %NotificationPreference{},
        attrs \\ %{}
      ) do
    NotificationPreference.changeset(notification_preference, attrs)
  end

  @doc """
  Creates a sent_notification.

  ## Examples

      iex> create_sent_notification(%{field: value})
      {:ok, %SentNotification{}}

      iex> create_sent_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sent_notification(course_reg_id, content) do
    %SentNotification{}
    |> SentNotification.changeset(%{course_reg_id: course_reg_id, content: content})
    |> Repo.insert()
  end

  # PreferableTime
  @doc """
  Gets the preferable times using id number.
  """
  def get_preferable_time!(id), do: Repo.get!(PreferableTime, id)

  @doc """
  Gets all preferable times for a notification preference
  """
  def get_preferable_times_for_preference(notification_preference_id) do
    query =
      from(pt in Cadet.Notifications.PreferableTime,
        join: np in Cadet.Notifications.NotificationPreference,
        on: pt.notification_preference_id == np.id,
        where: np.id == ^notification_preference_id
      )

    Repo.all(query)
  end
end
