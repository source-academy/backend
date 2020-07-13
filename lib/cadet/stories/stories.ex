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

  def create_story(_user = %User{role: role}, attrs = %{}) do
    if role in @manage_stories_role do
      changeset =
        %Story{}
        |> Story.changeset(attrs)

      Repo.insert(changeset)
    else
      {:error, {:forbidden, "User is not permitted to upload"}}
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
      {:error, {:forbidden, "User is not permitted to upload"}}
    end
  end
end
