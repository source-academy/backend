defmodule Cadet.Accounts.Pages do
  @moduledoc """
  Provides functions to manage page data
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{CourseRegistration, Page}

  # Get time spent by user at a specific path
  def get_user_time_spent_at_path(user_id, path) do
    Page
    |> where([p], p.user_id == ^user_id and p.path == ^path)
    |> select([p], p.time_spent)
    |> Repo.one()
  end

  # Get all time spent entries for a specific user
  def get_user_all_time_spent(user_id) do
    Page
    |> where([p], p.user_id == ^user_id)
    |> select([p], {p.path, p.time_spent})
    |> order_by([p], desc: p.time_spent)
    |> Repo.all()
    |> Enum.into(%{})
  end

  # Get total time spent by a specific user
  def get_user_total_time_spent(user_id) do
    Page
    |> where([p], p.user_id == ^user_id)
    |> select([p], sum(p.time_spent))
    |> Repo.one()
  end

  # Get total time spent by a specific user on a specific course
  def get_user_total_time_spent_on_course(course_registration_id) do
    Page
    |> where([p], p.course_registration_id == ^course_registration_id)
    |> select([p], sum(p.time_spent))
    |> Repo.one()
  end

  # Get aggregate time spent for a specific course and path
  def get_aggregate_time_spent_at_path(course_id, path) do
    Page
    |> where([p], p.course_id == ^course_id and p.path == ^path)
    |> select([p], sum(p.time_spent))
    |> Repo.one()
  end

  # Get aggregate time spent for a specific course (all paths)
  def get_aggregate_time_spent_on_course(course_id) do
    Page
    |> where([p], p.course_id == ^course_id)
    |> select([p], sum(p.time_spent))
    |> Repo.one()
  end

  # Upsert time spent for a user on a specific path
  def upsert_time_spent_by_user(user_id, path, time_spent) do
    Page
    |> where([p], p.user_id == ^user_id and p.path == ^path)
    |> Repo.one()
    |> case do
      # If no entry found, create a new one
      nil ->
        %Page{user_id: user_id, path: path, time_spent: time_spent}
        |> Repo.insert()

      # If entry exists, update the time_spent
      page ->
        page
        |> Page.changeset(%{time_spent: page.time_spent + time_spent})
        |> Repo.update()
    end
  end

  # Upsert time spent for a user on a specific path
  def upsert_time_spent_by_course_registration(course_registration_id, path, time_spent) do
    Page
    |> where([p], p.course_registration_id == ^course_registration_id and p.path == ^path)
    |> Repo.one()
    |> case do
      nil ->
        {user_id, course_id} =
          CourseRegistration
          |> where([c], c.id == ^course_registration_id)
          |> select([c], {c.user_id, c.course_id})
          |> Repo.one()

        %Page{
          user_id: user_id,
          course_registration_id: course_registration_id,
          course_id: course_id,
          path: path,
          time_spent: time_spent
        }
        |> Repo.insert()

      page ->
        page
        # Properly pass the map to the changeset
        |> Page.changeset(%{time_spent: page.time_spent + time_spent})
        |> Repo.update()
    end
  end
end
