defmodule Cadet.Accounts.Notifications do
  @moduledoc """
  Provides functions to fetch, write and acknowledge notifications.
  """

  use Cadet, :context

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{Notification, User}
  alias Cadet.Assessments.Submission
  alias Ecto.Multi

  @doc """
  Fetches all unread notifications belonging to a user as an array
  """
  @spec fetch(%User{}) :: {:ok, {:array, Notification}}
  def fetch(user = %User{}) do
    notifications =
      Notification
      |> where(user_id: ^user.id)
      |> where(read: false)
      |> preload(:assessment)
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
           user_id: user_id,
           assessment_id: assessment_id,
           type: type
         }
       ) do
    Notification
    |> where(user_id: ^user_id)
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
           user_id: user_id,
           submission_id: submission_id,
           type: type
         }
       ) do
    Notification
    |> where(user_id: ^user_id)
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
  @spec acknowledge({:array, :integer}, %User{}) :: {:ok, Ecto.Schema.t()} | {:error, :any}
  def acknowledge(notification_ids, user = %User{}) when is_list(notification_ids) do
    Multi.new()
    |> Multi.run(:update_all, fn _repo, _ ->
      Enum.reduce_while(notification_ids, {:ok, nil}, fn n_id, acc ->
        # credo:disable-for-next-line
        case acc do
          {:ok, _} ->
            {:cont, acknowledge(n_id, user)}

          _ ->
            {:halt, acc}
        end
      end)
    end)
    |> Repo.transaction()
  end

  @spec acknowledge(:integer, %User{}) :: {:ok, Ecto.Schema.t()} | {:error, :any}
  def acknowledge(notification_id, user = %User{}) do
    notification = Repo.get_by(Notification, id: notification_id, user_id: user.id)

    case notification do
      nil ->
        {:error, {:not_found, "Notification does not exist or does not belong to user"}}

      notification ->
        notification
        |> Notification.changeset(%{role: user.role, read: true})
        |> Repo.update()
    end
  end

  @doc """
  Function that handles notifications when a submission is unsubmitted.
  """
  @spec handle_unsubmit_notifications(:integer, %User{}) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def handle_unsubmit_notifications(assessment_id, student = %User{})
      when is_ecto_id(assessment_id) do
    # Fetch and delete all notifications of :autograded and :graded
    # Add new notification :unsubmitted

    Notification
    |> where(user_id: ^student.id)
    |> where(assessment_id: ^assessment_id)
    |> where([n], n.type in ^[:autograded, :graded])
    |> Repo.delete_all()

    write(%{
      type: :unsubmitted,
      role: student.role,
      user_id: student.id,
      assessment_id: assessment_id
    })
  end

  @doc """
  Writes a notification that a student's submission has been
  graded successfully. (for the student)
  """
  @spec write_notification_when_graded(integer(), any()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_when_graded(submission_id, type) when type in [:graded, :autograded] do
    submission =
      Submission
      |> Repo.get_by(id: submission_id)

    write(%{
      type: type,
      read: false,
      role: :student,
      user_id: submission.student_id,
      assessment_id: submission.assessment_id
    })
  end

  @doc """
  Writes a notification to all students that a new assessment is available.
  """
  @spec write_notification_for_new_assessment(integer()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_for_new_assessment(assessment_id) when is_ecto_id(assessment_id) do
    Multi.new()
    |> Multi.run(:insert_all, fn _repo, _ ->
      User
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
               user_id: student.id,
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
  @spec write_notification_when_student_submits(%Submission{}) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_when_student_submits(submission = %Submission{}) do
    avenger_id = get_avenger_id_of(submission.student_id)

    write(%{
      type: :submitted,
      read: false,
      role: :staff,
      user_id: avenger_id,
      assessment_id: submission.assessment_id,
      submission_id: submission.id
    })
  end

  @doc """
  When a student enters a message in chatkit, the student's avenger is notified
  """
  @spec write_notification_for_chatkit_avenger(%User{}, integer()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_for_chatkit_avenger(user = %User{}, assessment_id)
      when is_ecto_id(assessment_id) do
    submission = Repo.get_by(Submission, assessment_id: assessment_id, student_id: user.id)

    write(%{
      type: :new_message,
      role: :staff,
      user_id: get_avenger_id_of(user.id),
      assessment_id: submission.assessment_id,
      submission_id: submission.id
    })
  end

  def write_notification_for_chatkit_avenger(_, assessment_id),
    do: write(%{assessment_id: assessment_id})

  @doc """
  Similarly, when an avenger enters a message in chatkit, the student of the submission
  the chatkit is in will be notified
  """
  @spec write_notification_for_chatkit_student(%User{}, integer()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write_notification_for_chatkit_student(_, submission_id) when is_ecto_id(submission_id) do
    submission = Repo.get_by(Submission, id: submission_id)

    write(%{
      type: :new_message,
      role: :student,
      user_id: submission.student_id,
      assessment_id: submission.assessment_id
    })
  end

  def write_notification_for_chatkit_student(_, submission_id),
    do: write(%{submission_id: submission_id})

  defp get_avenger_id_of(student_id) when is_ecto_id(student_id) do
    User
    |> Repo.get_by(id: student_id)
    |> Repo.preload(:group)
    |> Map.get(:group)
    |> case do
      nil -> nil
      group -> Map.get(group, :leader_id)
    end
  end
end
