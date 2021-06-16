defmodule Cadet.Accounts.CourseRegistrations do
  @moduledoc """
  Provides functions fetch, add, update course_registration
  """
  use Cadet, [:context, :display]

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{User, CourseRegistration}
  alias Cadet.Courses.AssessmentType

  # guide
  # only join with User if need name or user name
  # only join with Group if need leader/mentor/students in group
  # only join with Course if need course info/config
  # otherwise just use CourseRegistration

  def get_user_record(user_id, course_id) when is_ecto_id(user_id) and is_ecto_id(course_id) do
    CourseRegistration
    |> where([cr], cr.user_id == ^user_id)
    |> where([cr], cr.course_id == ^course_id)
    |> preload(:course)
    |> preload(:group)
    |> Repo.one()
  end

  def get_user_course(user_id, course_id) when is_ecto_id(user_id) and is_ecto_id(course_id) do
    CourseRegistration
    |> where([cr], cr.user_id == ^user_id)
    |> where([cr], cr.course_id == ^course_id)
    |> join(:inner, [cr], c in assoc(cr, :course))
    |> join(:left, [cr, c], t in assoc(c, :assessment_type))
    |> preload([cr, c, t],
      course: {c, assessment_type: ^from(t in AssessmentType, order_by: [asc: t.order])}
    )
    |> preload(:group)
    |> Repo.one()
  end

  def get_courses(%User{id: id}) do
    CourseRegistration
    |> where([cr], cr.user_id == ^id)
    |> join(:inner, [cr], c in assoc(cr, :course))
    |> preload(:course)
    |> Repo.all()
  end

  def get_users(course_id) when is_ecto_id(course_id) do
    CourseRegistration
    |> where([cr], cr.course_id == ^course_id)
    |> join(:inner, [cr], u in assoc(cr, :user))
    |> preload(:user)
    |> Repo.all()
  end

  def get_users(course_id, group_id) when is_ecto_id(group_id) and is_ecto_id(course_id) do
    CourseRegistration
    |> where([cr], cr.course_id == ^course_id)
    |> where([cr], cr.group_id == ^group_id)
    |> join(:inner, [cr], u in assoc(cr, :user))
    |> join(:inner, [cr, u], g in assoc(cr, :group))
    |> preload(:user)
    |> preload(:group)
    |> Repo.all()
  end

  def enroll_course(params = %{user_id: user_id, course_id: course_id, role: _role})
      when is_ecto_id(user_id) and is_ecto_id(course_id) do
    params |> insert_or_update_course_registration()
  end

  @spec insert_or_update_course_registration(map()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update_course_registration(
        params = %{user_id: user_id, course_id: course_id, role: _role}
      )
      when is_ecto_id(user_id) and is_ecto_id(course_id) do
    CourseRegistration
    |> where(user_id: ^user_id)
    |> where(course_id: ^course_id)
    |> Repo.one()
    |> case do
      nil -> CourseRegistration.changeset(%CourseRegistration{}, params)
      cr -> CourseRegistration.changeset(cr, params)
    end
    |> Repo.insert_or_update()
  end

  @spec delete_record(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def delete_record(params = %{user_id: user_id, course_id: course_id})
      when is_ecto_id(user_id) and is_ecto_id(course_id) do
    CourseRegistration
    |> where(user_id: ^user_id)
    |> where(course_id: ^course_id)
    |> Repo.one()
    |> case do
      nil -> CourseRegistration.changeset(%CourseRegistration{}, params)
      cr -> CourseRegistration.changeset(cr, params)
    end
    |> Repo.delete()
  end

  def update_game_states(cr = %CourseRegistration{}, new_game_state = %{}) do
    case cr
         |> CourseRegistration.changeset(%{game_states: new_game_state})
         |> Repo.update() do
      result = {:ok, _} -> result
      {:error, changeset} -> {:error, {:internal_server_error, full_error_messages(changeset)}}
    end
  end
end
