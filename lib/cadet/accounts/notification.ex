defmodule Cadet.Accounts.Notification do
  @moduledoc """
  The Notification entity represents a notification.
  It stores information pertaining to the type of notification and who it belongs to.
  Each notification can have an assessment id or submission id, with optional question id.
  This will be used to pinpoint where the notification will be showed on the frontend.
  """
  use Cadet, :model

  alias Cadet.Accounts.{NotificationType, Role, User}
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
        validate_required(changeset, [:submission_id, :assessment_id])

      :student ->
        validate_required(changeset, [:assessment_id])

      _ ->
        add_error(changeset, :role, "Invalid role")
    end
  end
end
