defmodule Cadet.Stories.Stories do
  @moduledoc """
  Manages stories for the Source Academy game
  """
  use Cadet, [:context]

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Stories.Story
  alias Cadet.Courses.Course

  @manage_stories_role ~w(staff admin)a

  def list_stories(
        _user_course_registration = %CourseRegistration{course_id: course_id, role: role}
      ) do
    if role in @manage_stories_role do
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

  def create_story(
        attrs = %{},
        _user_course_registration = %CourseRegistration{course_id: course_id, role: role}
      ) do
    if role in @manage_stories_role do
      course =
        Course
        |> where(id: ^course_id)
        |> Repo.one()

      %Story{}
      |> Story.changeset(Map.put(attrs, :course_id, course.id))
      |> Repo.insert()
    else
      {:error, {:forbidden, "User not allowed to manage stories"}}
    end
  end

  def update_story(
        attrs = %{},
        id,
        _user_course_registration = %CourseRegistration{course_id: course_id, role: role}
      ) do
    if role in @manage_stories_role do
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
    else
      {:error, {:forbidden, "User not allowed to manage stories"}}
    end
  end

  def delete_story(
        id,
        _user_course_registration = %CourseRegistration{course_id: course_id, role: role}
      ) do
    if role in @manage_stories_role do
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
    else
      {:error, {:forbidden, "User not allowed to manage stories"}}
    end
  end
end
