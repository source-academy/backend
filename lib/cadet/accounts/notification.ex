defmodule Cadet.Accounts.Notification do
  @moduledoc """
  Provides the Notification schema as well as functions to
  fetch, write and acknowledge notifications
  """
  use Cadet, :model

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.{Notification, NotificationType, Role, User}
  alias Cadet.Assessments.{Assessment, Question, Submission}

  schema "notifications" do
    field(:type, NotificationType)
    field(:read, :boolean, default: false)
    field(:role, Role, virtual: true)

    belongs_to(:user, User)
    belongs_to(:assessment, Assessment)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)

    timestamps()
  end

  @required_fields ~w(type read role user_id)a
  @optional_fields ~w(assessment_id submission_id question_id)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_assessment_or_submission()
    |> foreign_key_constraint(:user)
    |> foreign_key_constraint(:assessment_id)
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
  end

  defp validate_assessment_or_submission(changeset) do
    case get_change(changeset, :role) do
      :staff ->
        validate_required(changeset, [:submission_id])

      :student ->
        validate_required(changeset, [:assessment_id])

      _ ->
        add_error(changeset, :role, "Invalid role")
    end
  end

  @doc """
  Fetches all notifications belonging to a user as an array
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
  @spec write(:any) :: Ecto.Changeset.t()
  def write(params = %{role: role}) do
    case role do
      :student -> write_student(params)
      :staff -> write_avenger(params)
      _ -> {:error, changeset(%Notification{}, params)}
    end
  end

  def write(params), do: {:error, changeset(%Notification{}, params)}

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
        changeset(%Notification{}, params)

      notification ->
        notification
        |> changeset(%{
          read: false,
          role: :student
        })
    end
    |> Repo.insert_or_update()
  end

  defp write_student(params), do: {:error, changeset(%Notification{}, params)}

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
        changeset(%Notification{}, params)

      notification ->
        notification
        |> changeset(%{
          read: false,
          role: :staff
        })
    end
    |> Repo.insert_or_update()
  end

  defp write_avenger(params), do: {:error, changeset(%Notification{}, params)}

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
        |> changeset(%{role: user.role, read: true})
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
end
