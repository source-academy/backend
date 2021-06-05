defmodule Cadet.Accounts.Query do
  @moduledoc """
  Generate queries related to the Accounts context
  """
  import Ecto.Query

  alias Cadet.Accounts.{User, CourseRegistration}
  alias Cadet.Course.Group
  alias Cadet.Repo

  # :TODO test
  def all_students(course_id) do
    User
    |> in_course(course_id)
    |> where([u, cr], cr.role == "student")
    |> preload(:group)
    |> Repo.all()
  end

  def username(username) do
    User
    |> of_username(username)
  end

  # :TODO test
  @spec students_of(%CourseRegistration{}) :: Ecto.Query.t()
  def students_of(%CourseRegistration{user_id: id, role: :staff, course_id: course_id}) do
    CourseRegistration
    |> where([cr], cr.course_id == ^course_id)
    |> join(:inner, [cr], g in Group, on: cr.group_id == g.id)
    |> where([cr, g], g.leader_id == ^id)
  end

  # :TODO test
  def avenger_of?(avenger_id, course_id, student_id) do
    avengerInCourse =
      CourseRegistration
      |> where([cr], cr.course_id = ^course_id)
      |> where([cr], cr.user_id = ^avenger_id)

    students = students_of(avengerInCourse)

    students
    |> Repo.get_by(user_id: ^student_id)
    |> case do
      nil -> false
      _ -> true
    end
  end

  defp of_username(query, username) do
    query |> where([a], a.username == ^username)
  end

  # :TODO test
  defp in_course(user, course_id) do
    user
    |> join(:inner, [u], cr in CourseRegistration, on: u.id == cr.user_id)
    |> where([_, cr], cr.id == ^course_id)
  end
end
