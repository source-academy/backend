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
      :staff -> write_avenger(params)
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
    question_id = Map.get(params, :question_id)

    Notification
    |> where(user_id: ^user_id)
    |> where(assessment_id: ^assessment_id)
    |> where(type: ^type)
    |> query_question_id(question_id)
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

  defp write_avenger(
         params = %{
           user_id: user_id,
           submission_id: submission_id,
           type: type
         }
       ) do
    question_id = Map.get(params, :question_id)

    Notification
    |> where(user_id: ^user_id)
    |> where(submission_id: ^submission_id)
    |> query_question_id(question_id)
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

  defp write_avenger(params), do: {:error, Notification.changeset(%Notification{}, params)}

  defp query_question_id(query, question_id) do
    case question_id do
      nil -> query
      question_id -> where(query, question_id: ^question_id)
    end
  end

  @doc """
  Changes a notification's read status from false to true.
  """
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
    avenger_id =
      User
      |> Repo.get_by(id: submission.student_id)
      |> Repo.preload(:group)
      |> Map.get(:group)
      |> case do
        nil -> nil
        group -> Map.get(group, :leader_id)
      end

    write(%{
      type: :submitted,
      read: false,
      role: :staff,
      user_id: avenger_id,
      assessment_id: submission.assessment_id,
      submission_id: submission.id
    })
  end
end
