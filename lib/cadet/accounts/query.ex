defmodule Cadet.Accounts.Query do
  @moduledoc """
  Generate queries related to the Accounts context
  """
  import Ecto.Query

  alias Cadet.Accounts.{User, CourseRegistration}
  alias Cadet.Repo

  def all_students(course_id) do
    User
    |> in_course(course_id)
    |> where([u, cr], cr.role == "student")
    |> Repo.all()
  end

  def username(username) do
    User
    |> of_username(username)
    |> preload(:latest_viewed_course)
  end

  @spec students_of(CourseRegistration.t()) :: Ecto.Query.t()
  def students_of(course_reg = %CourseRegistration{course_id: course_id}) do
    # Note that staff role is not check here as we assume that
    # group leader is assign to a staff validated by group changeset
    CourseRegistration
    |> where([cr], cr.course_id == ^course_id)
    |> join(:inner, [cr], g in assoc(cr, :group))
    |> where([cr, g], g.leader_id == ^course_reg.id)
  end

  def avenger_of?(avenger, student_id) do
    students = students_of(avenger)

    students
    |> Repo.get_by(id: student_id)
    |> case do
      nil -> false
      _ -> true
    end
  end

  defp of_username(query, username) do
    query |> where([a], a.username == ^username)
  end

  defp in_course(user, course_id) do
    user
    |> join(:inner, [u], cr in CourseRegistration, on: u.id == cr.user_id)
    |> where([_, cr], cr.course_id == ^course_id)
  end
end
