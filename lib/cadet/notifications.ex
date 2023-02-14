defmodule Cadet.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias Cadet.Repo

  alias Cadet.Notifications.NotificationType
  alias Cadet.Notifications.NotificationConfig

  @doc """
  Returns the list of notification_types.

  ## Examples

      iex> list_notification_types()
      [%NotificationType{}, ...]

  """
  def list_notification_types do
    Repo.all(NotificationType)
  end

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
  Creates a notification_type.

  ## Examples

      iex> create_notification_type(%{field: value})
      {:ok, %NotificationType{}}

      iex> create_notification_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification_type(attrs \\ %{}) do
    %NotificationType{}
    |> NotificationType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notification_type.

  ## Examples

      iex> update_notification_type(notification_type, %{field: new_value})
      {:ok, %NotificationType{}}

      iex> update_notification_type(notification_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification_type(%NotificationType{} = notification_type, attrs) do
    notification_type
    |> NotificationType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notification_type.

  ## Examples

      iex> delete_notification_type(notification_type)
      {:ok, %NotificationType{}}

      iex> delete_notification_type(notification_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification_type(%NotificationType{} = notification_type) do
    Repo.delete(notification_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification_type changes.

  ## Examples

      iex> change_notification_type(notification_type)
      %Ecto.Changeset{data: %NotificationType{}}

  """
  def change_notification_type(%NotificationType{} = notification_type, attrs \\ %{}) do
    NotificationType.changeset(notification_type, attrs)
  end

  @doc """
  Returns the list of notification_configs.

  ## Examples

      iex> list_notification_configs()
      [%NotificationConfig{}, ...]

  """
  def list_notification_configs do
    Repo.all(NotificationConfig)
  end

  @doc """
  Gets a single notification_config.

  Raises `Ecto.NoResultsError` if the Notification config does not exist.

  ## Examples

      iex> get_notification_config!(123)
      %NotificationConfig{}

      iex> get_notification_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification_config!(id), do: Repo.get!(NotificationConfig, id)

  @doc """
  Creates a notification_config.

  ## Examples

      iex> create_notification_config(%{field: value})
      {:ok, %NotificationConfig{}}

      iex> create_notification_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification_config(attrs \\ %{}) do
    %NotificationConfig{}
    |> NotificationConfig.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a notification_config.

  ## Examples

      iex> update_notification_config(notification_config, %{field: new_value})
      {:ok, %NotificationConfig{}}

      iex> update_notification_config(notification_config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification_config(%NotificationConfig{} = notification_config, attrs) do
    notification_config
    |> NotificationConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notification_config.

  ## Examples

      iex> delete_notification_config(notification_config)
      {:ok, %NotificationConfig{}}

      iex> delete_notification_config(notification_config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification_config(%NotificationConfig{} = notification_config) do
    Repo.delete(notification_config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification_config changes.

  ## Examples

      iex> change_notification_config(notification_config)
      %Ecto.Changeset{data: %NotificationConfig{}}

  """
  def change_notification_config(%NotificationConfig{} = notification_config, attrs \\ %{}) do
    NotificationConfig.changeset(notification_config, attrs)
  end

  alias Cadet.Notifications.TimeOption

  @doc """
  Returns the list of time_options.

  ## Examples

      iex> list_time_options()
      [%TimeOption{}, ...]

  """
  def list_time_options do
    Repo.all(TimeOption)
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
  Updates a time_option.

  ## Examples

      iex> update_time_option(time_option, %{field: new_value})
      {:ok, %TimeOption{}}

      iex> update_time_option(time_option, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_time_option(%TimeOption{} = time_option, attrs) do
    time_option
    |> TimeOption.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a time_option.

  ## Examples

      iex> delete_time_option(time_option)
      {:ok, %TimeOption{}}

      iex> delete_time_option(time_option)
      {:error, %Ecto.Changeset{}}

  """
  def delete_time_option(%TimeOption{} = time_option) do
    Repo.delete(time_option)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking time_option changes.

  ## Examples

      iex> change_time_option(time_option)
      %Ecto.Changeset{data: %TimeOption{}}

  """
  def change_time_option(%TimeOption{} = time_option, attrs \\ %{}) do
    TimeOption.changeset(time_option, attrs)
  end
end
