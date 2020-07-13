defmodule Cadet.Stories.Stories do
  @moduledoc """
  Assessments context contains domain logic for stories management
  for Source academy's game component
  """

  alias Cadet.Repo
  import Ecto.Query

  alias Cadet.Accounts.User
  alias Cadet.Stories.Story

  @manage_stories_role ~w(staff admin)a

  def list_stories(_user = %User{role: role}) do
    if role in @manage_stories_role do
      Repo.all(Story)
    else
      Story
      |> where(is_published: ^true)
      |> Repo.all()
    end
  end

  def create_story(_user = %User{role: role}, attrs = %{}) do
    if role in @manage_stories_role do
      changeset =
        %Story{}
        |> Story.changeset(attrs)

      Repo.insert(changeset)
    else
      {:error, {:forbidden, "User not allowed to manage stories"}}
    end
  end

  def update_story(_user = %User{role: role}, attrs = %{}, id) do
    if role in @manage_stories_role do
      Story
      |> where(id: ^id)
      |> Repo.one()
      |> Story.changeset(attrs)
      |> Repo.update()
    else
      {:error, {:forbidden, "User not allowed to manage stories"}}
    end
  end

  def delete_story(_user = %User{role: role}, id) do
    if role in @manage_stories_role do
      Story
      |> where(id: ^id)
      |> Repo.one()
      |> Repo.delete()
    else
      {:error, {:forbidden, "User not allowed to manage stories"}}
    end
  end
end
