defmodule Cadet.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias Cadet.Repo

  alias Cadet.Notifications.{
    NotificationType,
    NotificationConfig,
    SentNotification,
    TimeOption,
    NotificationPreference
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
      from(n in Cadet.Notifications.NotificationConfig,
        join: ntype in Cadet.Notifications.NotificationType,
        on: n.notification_type_id == ntype.id,
        where: n.notification_type_id == ^notification_type_id and n.course_id == ^course_id
      )

    query =
      if is_nil(assconfig_id) do
        where(query, [c], is_nil(c.assessment_config_id))
      else
        where(query, [c], c.assessment_config_id == ^assconfig_id)
      end

    Repo.one(query)
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

  # @doc """
  # Returns the list of sent_notifications.

  # ## Examples

  #    iex> list_sent_notifications()
  #    [%SentNotification{}, ...]

  # """

  # def list_sent_notifications do
  #   Repo.all(SentNotification)
  # end

  # @doc """
  # Gets a single sent_notification.

  # Raises `Ecto.NoResultsError` if the Sent notification does not exist.

  # ## Examples

  #     iex> get_sent_notification!(123)
  #     %SentNotification{}

  #     iex> get_sent_notification!(456)
  #     ** (Ecto.NoResultsError)

  # """
  # # def get_sent_notification!(id), do: Repo.get!(SentNotification, id)
end
