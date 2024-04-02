defmodule Cadet.Accounts.Notifications do
  @moduledoc """
  Provides functions to fetch, write and acknowledge notifications.
  """

  use Cadet, :context

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{Notification, CourseRegistration, CourseRegistration, Team, TeamMember}
  alias Cadet.Assessments.Submission
  alias Ecto.Multi

  @doc """
  Fetches all unread notifications belonging to a course_reg as an array
  """
  @spec fetch(CourseRegistration.t()) :: {:ok, {:array, Notification}}
  def fetch(course_reg = %CourseRegistration{}) do
    notifications =
      Notification
      |> where(course_reg_id: ^course_reg.id)
      |> where(read: false)
      |> join(:inner, [n], a in assoc(n, :assessment))
      |> preload([n, a], assessment: {a, :config})
      |> Repo.all()

    {:ok, notifications}
  end

  @doc """
  Writes a new notification into the database, or updates an existing one
  """
  @spec write(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write(params = %{role: role}) do
    case role do
      :student -> write_student(params)
      :staff -> write_staff(params)
      _ -> {:error, Notification.changeset(%Notification{}, params)}
    end
  end

  def write(params), do: {:error, Notification.changeset(%Notification{}, params)}

  defp write_student(
         params = %{
           course_reg_id: course_reg_id,
           assessment_id: assessment_id,
           type: type
         }
       ) do
    Notification
    |> where(course_reg_id: ^course_reg_id)
    |> where(assessment_id: ^assessment_id)
    |> where(type: ^type)
    |> Repo.one()
    |> case do
      nil ->
        Notification.changeset(%Notification{}, params)

      notification ->
        notification
        |> Notification.changeset(%{
          read: false,
          role: :student
        })
    end
    |> Repo.insert_or_update()
  end

  defp write_student(params), do: {:error, Notification.changeset(%Notification{}, params)}

  defp write_staff(
         params = %{
           course_reg_id: course_reg_id,
           submission_id: submission_id,
           type: type
         }
       ) do
    Notification
    |> where(course_reg_id: ^course_reg_id)
    |> where(submission_id: ^submission_id)
    |> where(type: ^type)
    |> Repo.one()
    |> case do
      nil ->
        Notification.changeset(%Notification{}, params)

      notification ->
        notification
        |> Notification.changeset(%{
          read: false,
          role: :staff
        })
    end
    |> Repo.insert_or_update()
  end

  defp write_staff(params), do: {:error, Notification.changeset(%Notification{}, params)}

  @doc """
  Changes read status of notification(s) from false to true.
  """
  @spec acknowledge({:array, :integer}, CourseRegistration.t()) ::
          {:ok, Ecto.Schema.t()}
          | {:error, any}
          | {:error, Ecto.Multi.name(), any, %{Ecto.Multi.name() => any}}
  def acknowledge(notification_ids, course_reg = %CourseRegistration{})
      when is_list(notification_ids) do
    Multi.new()
    |> Multi.run(:update_all, fn _repo, _ ->
      Enum.reduce_while(notification_ids, {:ok, nil}, fn n_id, acc ->
        # credo:disable-for-next-line
        case acc do
          {:ok, _} ->
            {:cont, acknowledge(n_id, course_reg)}

          _ ->
            {:halt, acc}
        end
      end)
    end)
    |> Repo.transaction()
  end

  @spec acknowledge(:integer, CourseRegistration.t()) :: {:ok, Ecto.Schema.t()} | {:error, any()}
  def acknowledge(notification_id, course_reg = %CourseRegistration{}) do
    notification = Repo.get_by(Notification, id: notification_id, course_reg_id: course_reg.id)

    case notification do
      nil ->
        {:error, {:not_found, "Notification does not exist or does not belong to user"}}

      notification ->
        notification
        |> Notification.changeset(%{role: course_reg.role, read: true})
        |> Repo.update()
    end
  end

  @doc """
  Function that handles notifications when a submission is unsubmitted.
  """
  @spec handle_unsubmit_notifications(integer(), CourseRegistration.t()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def handle_unsubmit_notifications(assessment_id, student = %CourseRegistration{})
      when is_ecto_id(assessment_id) do
    # Fetch and delete all notifications of :unpublished_grading
    # Add new notification :unsubmitted

    Notification
    |> where(course_reg_id: ^student.id)
    |> where(assessment_id: ^assessment_id)
    |> where([n], n.type in ^[:unpublished_grading])
    |> Repo.delete_all()

    write(%{
      type: :unsubmitted,
      role: :student,
      course_reg_id: student.id,
      assessment_id: assessment_id
    })
  end

  @doc """
  Function that handles notifications when a submission grade is unpublished.
  Deletes all :published notifications and adds a new :unpublished_grading notification.
  """
  @spec handle_unpublish_grades_notifications(integer(), CourseRegistration.t()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def handle_unpublish_grades_notifications(assessment_id, student = %CourseRegistration{})
      when is_ecto_id(assessment_id) do
    Notification
    |> where(course_reg_id: ^student.id)
    |> where(assessment_id: ^assessment_id)
    |> where([n], n.type in ^[:published_grading])
    |> Repo.delete_all()

    write(%{
      type: :unpublished_grading,
      read: false,
      role: :student,
      course_reg_id: student.id,
      assessment_id: assessment_id
    })
  end

  @doc """
  Writes a notification that a student's submission has been
  graded successfully. (for the student)
  """
  @spec write_notification_when_published(integer(), any()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_when_published(submission_id, type) when type in [:published_grading] do
    case Repo.get(Submission, submission_id) do
      nil ->
        {:error, %Ecto.Changeset{}}

      submission ->
        case submission.student_id do
          nil ->
            team = Repo.get(Team, submission.team_id)

            query =
              from(t in Team,
                join: tm in TeamMember,
                on: t.id == tm.team_id,
                join: cr in CourseRegistration,
                on: tm.student_id == cr.id,
                where: t.id == ^team.id,
                select: cr.id
              )

            team_members = Repo.all(query)

            Enum.each(team_members, fn tm_id ->
              write(%{
                type: type,
                read: false,
                role: :student,
                course_reg_id: tm_id,
                assessment_id: submission.assessment_id
              })
            end)

          student_id ->
            write(%{
              type: type,
              read: false,
              role: :student,
              course_reg_id: student_id,
              assessment_id: submission.assessment_id
            })
        end
    end
  end

  @doc """
  Writes a notification to all students that a new assessment is available.
  """
  @spec write_notification_for_new_assessment(integer(), integer()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_for_new_assessment(course_id, assessment_id)
      when is_ecto_id(assessment_id) and is_ecto_id(course_id) do
    Multi.new()
    |> Multi.run(:insert_all, fn _repo, _ ->
      CourseRegistration
      |> where(course_id: ^course_id)
      |> where(role: ^:student)
      |> Repo.all()
      |> Enum.reduce_while({:ok, nil}, fn student, acc ->
        # credo:disable-for-next-line
        case acc do
          {:ok, _} ->
            {:cont,
             write(%{
               type: :new,
               read: false,
               role: :student,
               course_reg_id: student.id,
               assessment_id: assessment_id
             })}

          _ ->
            {:halt, acc}
        end
      end)
    end)
    |> Repo.transaction()
  end

  @doc """
  When a student has finalized a submission, writes a notification to the corresponding
  grader (Avenger) in charge of the student.
  """
  @spec write_notification_when_student_submits(Submission.t()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_when_student_submits(submission = %Submission{}) do
    id =
      case submission.student_id do
        nil ->
          team_id = submission.team_id

          team =
            Repo.one(
              from(t in Team,
                where: t.id == ^team_id,
                preload: [:team_members]
              )
            )

          # Does not matter if team members have different Avengers
          # Just require one of them to be notified of the submission
          s_id = team.team_members |> hd() |> Map.get(:student_id)
          s_id

        _ ->
          submission.student_id
      end

    avenger_id = get_avenger_id_of(id)

    if is_nil(avenger_id) do
      {:ok, nil}
    else
      write(%{
        type: :submitted,
        read: false,
        role: :staff,
        course_reg_id: avenger_id,
        assessment_id: submission.assessment_id,
        submission_id: submission.id
      })
    end
  end

  defp get_avenger_id_of(student_id) when is_ecto_id(student_id) do
    CourseRegistration
    |> Repo.get_by(id: student_id)
    |> Repo.preload(:group)
    |> Map.get(:group)
    |> case do
      nil -> nil
      group -> Map.get(group, :leader_id)
    end
  end
end
