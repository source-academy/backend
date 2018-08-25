defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Accounts.User
  alias Cadet.Assessments.{Answer, Assessment, SubmissionStatus}

  schema "submissions" do
    field(:grade, :integer, virtual: true)
    field(:adjustment, :integer, virtual: true)
    field(:xp, :integer, virtual: true)
    field(:xp_adjustment, :integer, virtual: true)
    field(:xp_bonus, :integer, default: 0)
    field(:status, SubmissionStatus, default: :attempting)

    belongs_to(:assessment, Assessment)
    belongs_to(:student, User)
    has_many(:answers, Answer)

    timestamps()
  end

  @required_fields ~w(student_id assessment_id status)a
  @optional_fields ~w(xp_bonus)a
  @xp_early_submission_max_bonus 100

  def changeset(submission, params) do
    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_number(
      :xp_bonus,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: @xp_early_submission_max_bonus
    )
    |> add_belongs_to_id_from_model([:student, :assessment], params)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:assessment_id)
  end
end
