defmodule Cadet.Accounts.Query do
  @moduledoc """
  Generate queries related to the Accounts context
  """
  import Ecto.Query

  alias Cadet.Accounts.User
  alias Cadet.Courses.Group
  alias Cadet.Repo

  # This gets all users where each and every user is a student.
  def all_students do
    User
    |> where([u], u.role == "student")
    |> preload(:group)
    |> Repo.all()
  end

  def username(username) do
    User
    |> of_username(username)
  end

  @spec students_of(%User{}) :: Ecto.Query.t()
  def students_of(%User{id: id, role: :staff}) do
    User
    |> join(:inner, [u], g in Group, on: u.group_id == g.id)
    |> where([_, g], g.leader_id == ^id)
  end

  def avenger_of?(avenger, student_id) do
    students = students_of(avenger)

    students
    |> Repo.get(student_id)
    |> case do
      nil -> false
      _ -> true
    end
  end

  defp of_username(query, username) do
    query |> where([a], a.username == ^username)
  end
end
