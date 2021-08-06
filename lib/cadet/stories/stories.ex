defmodule Cadet.Stories.Stories do
  @moduledoc """
  Manages stories for the Source Academy game
  """
  use Cadet, [:context]

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Stories.Story

  def list_stories(course_id, list_all) do
    if list_all do
      Story
      |> where(course_id: ^course_id)
      |> Repo.all()
    else
      Story
      |> where(course_id: ^course_id)
      |> where(is_published: ^true)
      |> where([s], s.open_at <= ^Timex.now())
      |> Repo.all()
    end
  end

  def create_story(attrs = %{}, course_id) do
    %Story{}
    |> Story.changeset(Map.put(attrs, :course_id, course_id))
    |> Repo.insert()
  end

  def update_story(attrs = %{}, id, course_id) do
    case Repo.get(Story, id) do
      nil ->
        {:error, {:not_found, "Story not found"}}

      story ->
        if story.course_id == course_id do
          story
          |> Story.changeset(attrs)
          |> Repo.update()
        else
          {:error, {:forbidden, "User not allowed to manage stories from another course"}}
        end
    end
  end

  def delete_story(id, course_id) do
    case Repo.get(Story, id) do
      nil ->
        {:error, {:not_found, "Story not found"}}

      story ->
        if story.course_id == course_id do
          Repo.delete(story)
        else
          {:error, {:forbidden, "User not allowed to manage stories from another course"}}
        end
    end
  end
end
