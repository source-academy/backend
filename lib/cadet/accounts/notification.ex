defmodule Cadet.Accounts.Notification do
  use Cadet, :model

  alias Cadet.Repo
  alias Cadet.Accounts.NotificationType
  alias Cadet.Accounts.Role
  alias Cadet.Accounts.User
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.Assessment

  schema "notifications" do
    field(:type, NotificationType)
    field(:read, :boolean)
    field(:role, Role)

    belongs_to(:user, User)
    belongs_to(:assessment, Assessment)
    belongs_to(:submission, Submission)
    belongs_to(:question, Question)

    timestamps()
  end

  @required_fields ~w(type read role user_id)a
  @optional_fields ~w(assessment_id submission_id question_id)

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

  """
  # Consider another time
  @spec poll :: {:ok, :integer}
  def poll() do

  end
  """

  @doc """
  Fetches all notifications belonging to a user as an array
  """
  @spec fetch(%User{}) :: {:ok, {:array, Notification}}
  def fetch(user = %User{}) do
    IO.puts("Fetch called")
    IO.inspect(user)

    # Test
    {:ok, []}
  end

  @doc """
  Writes a new notification into the database
  """
  @spec write(:any) :: Ecto.Changeset.t()
  def write(params) do
    IO.puts("Write called")
  end

  @doc """
  Changes a notification's read status from false to true
  """
  @spec acknowledge(:integer, %User{}) :: {:ok} | {:error, Ecto.Changeset.t()}
  def acknowledge(notification_id, user = %User{}) do
    IO.puts("Acknowledge called")
    IO.puts("with notification id: ")
    IO.inspect(notification_id)
    IO.puts("with user: ")
    IO.inspect(user)

    # Test
    {:ok, nil}
  end
end
