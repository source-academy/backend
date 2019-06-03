defmodule Cadet.Accounts.Notification do
  use Cadet, :model

  alias Cadet.Repo
  alias Cadet.Accounts.NotificationType
  alias Cadet.Accounts.User
  alias Cadet.Assessments.Question
  alias Cadet.Assessments.Assessment

  schema "notification" do
    field(:type, NotificationType)
    field(:read, :boolean)

    belongs_to(:user, User)
    belongs_to(:assessment, Assessment)
    belongs_to(:question, Question)

    timestamps()
  end

  @required_fields ~w(type read user_id assessment_id)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ [:question_id])
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user)
    |> foreign_key_constraint(:assessment_id)
    |> foreign_key_constraint(:question_id)
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
