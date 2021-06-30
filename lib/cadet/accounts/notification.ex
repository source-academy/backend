defmodule Cadet.Accounts.Notification do
  @moduledoc """
  The Notification entity represents a notification.
  It stores information pertaining to the type of notification and who in which course it belongs to.
  Each notification can have an assessment id or submission id, with optional question id.
  This will be used to pinpoint where the notification will be showed on the frontend.
  """
  use Cadet, :model

  alias Cadet.Accounts.{NotificationType, Role, CourseRegistration}
  alias Cadet.Assessments.{Assessment, Submission}

  schema "notifications" do
    field(:type, NotificationType)
    field(:read, :boolean, default: false)
    field(:role, Role, virtual: true)

    belongs_to(:course_reg, CourseRegistration)
    belongs_to(:assessment, Assessment)
    belongs_to(:submission, Submission)

    timestamps()
  end

  @required_fields ~w(type read course_reg_id assessment_id)a
  @optional_fields ~w(submission_id)a

  def changeset(answer, params) do
    answer
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:course_reg_id)
    |> foreign_key_constraint(:assessment_id)
    |> foreign_key_constraint(:submission_id)
  end
end
