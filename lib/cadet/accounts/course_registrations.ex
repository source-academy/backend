defmodule Cadet.Accounts.CourseRegistrations do
  @moduledoc """
  Provides functions fetch, add, update course_registration
  """
  use Cadet, [:context, :display]

  import Ecto.Query
  require Logger

  alias Cadet.{Repo, Accounts}
  alias Cadet.Accounts.{User, CourseRegistration}
  alias Cadet.Assessments.{Answer, Submission}
  alias Cadet.Courses.AssessmentConfig

  # guide
  # only join with User if need name or user name
  # only join with Group if need leader/students in group
  # only join with Course if need course info/config
  # otherwise just use CourseRegistration

  def get_user_record(user_id, course_id) when is_ecto_id(user_id) and is_ecto_id(course_id) do
    Logger.info("Retrieving user record for user #{user_id} in course #{course_id}")

    result =
      CourseRegistration
      |> where([cr], cr.user_id == ^user_id)
      |> where([cr], cr.course_id == ^course_id)
      |> preload(:course)
      |> preload(:group)
      |> Repo.one()

    case result do
      nil ->
        Logger.error("User record not found for user #{user_id} in course #{course_id}")

      _ ->
        Logger.info(
          "Successfully retrieved user record for user #{user_id} in course #{course_id}"
        )
    end

    result
  end

  def get_user_course(user_id, course_id) when is_ecto_id(user_id) and is_ecto_id(course_id) do
    Logger.info("Retrieving course details for user #{user_id} in course #{course_id}")

    result =
      CourseRegistration
      |> where([cr], cr.user_id == ^user_id)
      |> where([cr], cr.course_id == ^course_id)
      |> join(:inner, [cr], c in assoc(cr, :course))
      |> join(:left, [cr, c], ac in assoc(c, :assessment_config))
      |> preload([cr, c, ac],
        course: {c, assessment_config: ^from(ac in AssessmentConfig, order_by: [asc: ac.order])}
      )
      |> preload(:group)
      |> Repo.one()

    case result do
      nil ->
        Logger.error("Course details not found for user #{user_id} in course #{course_id}")

      _ ->
        Logger.info(
          "Successfully retrieved course details for user #{user_id} in course #{course_id}"
        )
    end

    result
  end

  def get_courses(%User{id: id}) do
    Logger.info("Retrieving all courses for user #{id}")

    courses =
      CourseRegistration
      |> where([cr], cr.user_id == ^id)
      |> join(:inner, [cr], c in assoc(cr, :course))
      |> preload(:course)
      |> Repo.all()

    Logger.info("Retrieved #{length(courses)} courses for user #{id}")
    courses
  end

  def get_admin_courses_count(%User{id: id}) do
    CourseRegistration
    |> where(user_id: ^id)
    |> where(role: :admin)
    |> Repo.all()
    |> Enum.count()
  end

  def get_users(course_id) when is_ecto_id(course_id) do
    CourseRegistration
    |> where([cr], cr.course_id == ^course_id)
    |> join(:inner, [cr], u in assoc(cr, :user))
    |> preload(:user)
    |> Repo.all()
  end

  def get_staffs(course_id) do
    CourseRegistration
    |> where(course_id: ^course_id)
    |> where(role: :staff)
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

  def upsert_users_in_course(provider, usernames_and_roles, course_id) do
    usernames_and_roles
    |> Enum.reduce_while(nil, fn %{username: username, role: role}, _acc ->
      upsert_users_in_course_helper(provider, username, course_id, role)
    end)
  end

  defp upsert_users_in_course_helper(provider, username, course_id, role) do
    case User
         |> where(username: ^username, provider: ^provider)
         |> Repo.one() do
      nil ->
        case Accounts.register(%{username: username, provider: provider}) do
          {:ok, _} ->
            upsert_users_in_course_helper(provider, username, course_id, role)

          {:error, changeset} ->
            {:halt, {:error, {:bad_request, full_error_messages(changeset)}}}
        end

      user ->
        case enroll_course(%{user_id: user.id, course_id: course_id, role: role}) do
          {:ok, _} ->
            {:cont, :ok}

          {:error, changeset} ->
            {:halt, {:error, {:bad_request, full_error_messages(changeset)}}}
        end
    end
  end

  @doc """
  Enrolls the user into the specified course with the specified role, and updates the user's
  latest viewed course id to this enrolled course.
  """
  def enroll_course(params = %{user_id: user_id, course_id: course_id, role: _role})
      when is_ecto_id(user_id) and is_ecto_id(course_id) do
    Logger.info("Enrolling user #{user_id} in course #{course_id}")

    case params |> insert_or_update_course_registration() do
      {:ok, _course_reg} = ok ->
        # Ensures that the user has a latest_viewed_course
        User
        |> where(id: ^user_id)
        |> Repo.one()
        |> User.changeset(%{latest_viewed_course_id: course_id})
        |> Repo.update()

        Logger.info("Successfully enrolled user #{user_id} in course #{course_id}")
        ok

      {:error, changeset} = error ->
        Logger.error(
          "Failed to enroll user #{user_id} in course #{course_id}: #{full_error_messages(changeset)}"
        )

        error
    end
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

  def update_game_states(cr = %CourseRegistration{}, new_game_state) do
    case cr
         |> CourseRegistration.changeset(%{game_states: new_game_state})
         |> Repo.update() do
      result = {:ok, _} -> result
      {:error, changeset} -> {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  def update_role(role, coursereg_id) do
    case CourseRegistration |> where(id: ^coursereg_id) |> Repo.one() do
      nil ->
        {:error, {:bad_request, "User course registration does not exist"}}

      course_reg ->
        case course_reg
             |> CourseRegistration.changeset(%{role: role})
             |> Repo.update() do
          {:ok, _} = result -> result
          {:error, changeset} -> {:error, {:bad_request, full_error_messages(changeset)}}
        end
    end
  end

  def delete_course_registration(coursereg_id) do
    # TODO: Handle deletions of achievement entries, etc. too
    case CourseRegistration |> where(id: ^coursereg_id) |> Repo.one() do
      nil ->
        {:error, {:bad_request, "User course registration does not exist"}}

      course_reg ->
        # Delete submissions and answers before deleting user
        Submission
        |> where(student_id: ^course_reg.id)
        |> Repo.all()
        |> Enum.each(fn x ->
          Answer
          |> where(submission_id: ^x.id)
          |> Repo.delete_all()

          Repo.delete(x)
        end)

        Repo.delete(course_reg)
    end
  end

  def update_research_agreement(course_reg, agreed_to_research) do
    course_reg
    |> CourseRegistration.changeset(%{agreed_to_research: agreed_to_research})
    |> Repo.update()
    |> case do
      result = {:ok, _} -> result
      {:error, changeset} -> {:error, {:bad_request, full_error_messages(changeset)}}
    end
  end

  def get_avenger_of(student_id) when is_ecto_id(student_id) do
    CourseRegistration
    |> Repo.get_by(id: student_id)
    |> Repo.preload(:group)
    |> Map.get(:group)
    |> case do
      nil ->
        nil

      group ->
        avenger_id = Map.get(group, :leader_id)

        CourseRegistration
        |> where([cr], cr.id == ^avenger_id)
        |> preload(:user)
        |> Repo.one()
    end
  end
end
