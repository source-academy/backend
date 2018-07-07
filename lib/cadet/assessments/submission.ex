defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Assessments.SubmissionStatus
  alias Cadet.Accounts.User
  alias Cadet.Assessments.Assessment
  alias Cadet.Assessments.Answer

  # TODO: Add unique indices

  schema "submissions" do
    field(:status, SubmissionStatus, default: :attempting)
    field(:submitted_at, Timex.Ecto.DateTime)
    field(:override_xp, :integer)
    field(:xp, :integer, virtual: true)

    belongs_to(:assessment, Assessment)
    belongs_to(:student, User)
    belongs_to(:grader, User)
    has_many(:answers, Answer)

    timestamps()
  end

  @required_fields ~w(status student_id assessment_id)a
  @optional_fields ~w(override_xp submitted_at)a

  def changeset(submission, params) do
    params = convert_date(params, :submitted_at)

    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> add_belongs_to_id_from_model(:student, params)
    |> add_belongs_to_id_from_model(:assessment, params)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:student)
    |> foreign_key_constraint(:assessment)
  end
end
