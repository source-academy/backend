defmodule Cadet.Stories.Stories do
  @moduledoc """
  Manages stories for the Source Academy game
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger

  alias Cadet.Repo
  alias Cadet.Stories.Story

  def list_stories(course_id, list_all) do
    Logger.info("Listing stories for course #{course_id}, list_all: #{list_all}")

    stories =
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

    Logger.info("Retrieved #{length(stories)} stories for course #{course_id}")
    stories
  end

  def create_story(attrs = %{}, course_id) do
    Logger.info("Creating new story for course #{course_id}")

    case %Story{}
         |> Story.changeset(Map.put(attrs, :course_id, course_id))
         |> Repo.insert() do
      {:ok, story} = result ->
        Logger.info("Successfully created story #{story.id} for course #{course_id}")
        result

      {:error, changeset} ->
        Logger.error(
          "Failed to create story for course #{course_id}: #{full_error_messages(changeset)}"
        )

        {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  def update_story(attrs = %{}, id, course_id) do
    Logger.info("Updating story #{id} for course #{course_id}")

    case Repo.get(Story, id) do
      nil ->
        Logger.error("Cannot update story #{id} - story not found")
        {:error, {:not_found, "Story not found"}}

      story ->
        if story.course_id == course_id do
          result =
            story
            |> Story.changeset(attrs)
            |> Repo.update()

          case result do
            {:ok, _} ->
              Logger.info("Successfully updated story #{id}")

            {:error, changeset} ->
              Logger.error("Failed to update story #{id}: #{full_error_messages(changeset)}")
          end

          result
        else
          Logger.error(
            "Cannot update story #{id} - user not allowed to manage stories from another course"
          )

          {:error, {:forbidden, "User not allowed to manage stories from another course"}}
        end
    end
  end

  def delete_story(id, course_id) do
    Logger.info("Deleting story #{id} for course #{course_id}")

    case Repo.get(Story, id) do
      nil ->
        Logger.error("Cannot delete story #{id} - story not found")
        {:error, {:not_found, "Story not found"}}

      story ->
        if story.course_id == course_id do
          result = Repo.delete(story)

          case result do
            {:ok, _} ->
              Logger.info("Successfully deleted story #{id}")

            {:error, changeset} ->
              Logger.error("Failed to delete story #{id}: #{full_error_messages(changeset)}")
          end

          result
        else
          Logger.error(
            "Cannot delete story #{id} - user not allowed to manage stories from another course"
          )

          {:error, {:forbidden, "User not allowed to manage stories from another course"}}
        end
    end
  end
end
