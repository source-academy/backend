defmodule Cadet.Accounts.CourseRegistrations do
  @moduledoc """
  Provides functions fetch, add, update course_registration
  """
  use Cadet, :context

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{User, CourseRegistration}

  # guide
  # only join with User if need name or user name
  # only join with Group if need leader/mentor/students in group
  # only join with Course if need course info/config
  # otherwise just use CourseRegistration

  def get_courses(%User{id: id}) do
    CourseRegistration
    |> where([cr], cr.user_id == ^id)
    |> join(:inner, [cr], c in assoc(cr, :course))
  end

  def get_users(course_id) do
    CourseRegistration
    |> where([cr], cr.course_id == ^course_id)
    |> join(:inner, [cr], u in assoc(cr, :user))
  end

  def get_users(course_id, group_id) do
    get_users(course_id)
    |> where([cr, u], cr.group_id == ^group_id)

    # |> join(:inner, [cr, u], g in assoc(cr, :group))
    # maybe not needed when we dont need group info
  end

  def enroll_course(params = %{user_id: user_id, course_id: course_id, role: role})
      when is_ecto_id(user_id) && is_ecto_id(course_id) do
    params |> insert_or_update_course_registration()
  end

  @spec insert_or_update_course_registration(map()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update_course_registration(params = %{user_id: user_id, course_id: course_id})
      when is_ecto_id(user_id) && is_ecto_id(course_id) do
    CourseRegistration
    |> where(user_id: ^user_id)
    |> where(course_id: ^course_id)
    |> Repo.one()
    |> case do
      nil ->
        CourseRegistration.changeset(%CourseRegistration{}, params)

      cr ->
        CourseRegistration.changeset(cr, params)
    end
    |> Repo.insert_or_update()
  end


end
