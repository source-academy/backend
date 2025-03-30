defmodule Cadet.Assessments.Submission do
  @moduledoc false
  use Cadet, :model

  alias Cadet.Accounts.{CourseRegistration, Team}
  alias Cadet.Assessments.{Answer, Assessment, SubmissionStatus}

  @type t :: %__MODULE__{}

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
    field(:submitted_at, :utc_datetime_usec)
    field(:is_grading_published, :boolean, default: false)

    belongs_to(:assessment, Assessment)
    belongs_to(:student, CourseRegistration)
    belongs_to(:team, Team)
    belongs_to(:unsubmitted_by, CourseRegistration)
    has_many(:answers, Answer, on_delete: :delete_all)

    timestamps()
  end

  @required_fields ~w(assessment_id status is_grading_published)a
  @optional_fields ~w(xp_bonus unsubmitted_by_id unsubmitted_at submitted_at student_id team_id)a

  def changeset(submission, params) do
    submission
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_number(
      :xp_bonus,
      greater_than_or_equal_to: 0
    )
    |> add_belongs_to_id_from_model([:team, :student, :assessment, :unsubmitted_by], params)
    |> validate_xor_relationship
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:assessment_id)
    |> foreign_key_constraint(:unsubmitted_by_id)
  end

  defp validate_xor_relationship(changeset) do
    case {get_field(changeset, :student_id), get_field(changeset, :team_id)} do
      {nil, nil} ->
        changeset
        |> add_error(:student_id, "either student or team_id must be present")
        |> add_error(:team_id, "either student_id or team must be present")

      {nil, _} ->
        changeset

      {_, nil} ->
        changeset

      {_student, _team} ->
        changeset
        |> add_error(:student_id, "student and team_id cannot be present at the same time")
        |> add_error(:team_id, "student_id and team cannot be present at the same time")
    end
  end
end
