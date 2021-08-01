defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Assessments.{Answer, Assessment, SubmissionStatus}

  schema "submissions" do
    field(:xp, :integer, virtual: true)
    field(:xp_adjustment, :integer, virtual: true)
    field(:xp_bonus, :integer, default: 0)
    field(:group_name, :string, virtual: true)
    field(:status, SubmissionStatus, default: :attempting)
    field(:question_count, :integer, virtual: true)
    field(:graded_count, :integer, virtual: true, default: 0)
    field(:grading_status, :string, virtual: true)
    field(:unsubmitted_at, :utc_datetime_usec)

    belongs_to(:assessment, Assessment)
    belongs_to(:student, CourseRegistration)
    belongs_to(:unsubmitted_by, CourseRegistration)
    has_many(:answers, Answer)

    timestamps()
  end

  @required_fields ~w(student_id assessment_id status)a
  @optional_fields ~w(xp_bonus unsubmitted_by_id unsubmitted_at)a

  def changeset(submission, params) do
    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_number(
      :xp_bonus,
      greater_than_or_equal_to: 0
    )
    |> add_belongs_to_id_from_model([:student, :assessment, :unsubmitted_by], params)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:assessment_id)
    |> foreign_key_constraint(:unsubmitted_by_id)
  end
end
