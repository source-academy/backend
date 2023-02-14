defmodule Cadet.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias Cadet.Repo

  alias Cadet.Notifications.NotificationType

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
end
