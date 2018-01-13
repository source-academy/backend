defmodule Cadet.Course do
  @moduledoc """
  Course context contains domain logic for Course administration
  management such as discussion groups, materials, and announcements
  """
  use Cadet, :context

  alias Cadet.Accounts.User
  alias Cadet.Course.Announcement

  @doc """
  Create announcement entity using specified user as poster
  """
  def create_announcement(poster = %User{}, attrs = %{}) do
    changeset =
      Announcement.changeset(%Announcement{}, attrs)
      |> put_assoc(:poster, poster)

    Repo.insert(changeset)
  end

  @doc """
  Edit Announcement with specified ID entity by specifying changes
  """
  def edit_announcement(id, changes = %{}) do
    announcement = Repo.get(Announcement, id)

    if announcement == nil do
      {:error, :not_found}
    else
      changeset = Announcement.changeset(announcement, changes)
      Repo.update(changeset)
    end
  end

  @doc """
  Get Announcement with specified ID
  """
  def get_announcement(id) do
    Repo.get(Announcement, id)
    |> Repo.preload(:poster)
  end

  @doc """
  Delete Announcement with specified ID
  """
  def delete_announcement(id) do
    announcement = Repo.get(Announcement, id)

    if announcement == nil do
      {:error, :not_found}
    else
      Repo.delete(announcement)
    end
  end
end
