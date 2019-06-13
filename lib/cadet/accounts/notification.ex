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
    field(:read, :boolean)
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
  Writes a new notification into the database
  """
  @spec write(:any) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def write(params) do
    %Notification{}
    |> changeset(params)
    |> Repo.insert()
  end

  @doc """
  Changes a notification's read status from false to true
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
end
