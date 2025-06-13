defmodule Cadet.Courses.AssessmentConfig do
  @moduledoc """
  The AssessmentConfig entity stores the assessment types in a
  particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.Course

  schema "assessment_configs" do
    field(:order, :integer)
    field(:type, :string)
    field(:show_grading_summary, :boolean, default: true)
    field(:is_manually_graded, :boolean, default: true)
    field(:has_token_counter, :boolean, default: false)
    field(:has_voting_features, :boolean, default: false)
    # used by frontend to determine display styles
    field(:early_submission_xp, :integer, default: 0)
    field(:hours_before_early_xp_decay, :integer, default: 0)
    field(:is_grading_auto_published, :boolean, default: false)
    # marks an assessment type as a minigame (with different submission and testcase behaviour)
    field(:is_minigame, :boolean, default: false)

    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(course_id)a
  @optional_fields ~w(order type early_submission_xp
    hours_before_early_xp_decay show_grading_summary is_manually_graded has_voting_features has_token_counter is_grading_auto_published is_minigame)a

  def changeset(assessment_config, params) do
    assessment_config
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:order, greater_than: 0)
    |> validate_number(:order, less_than_or_equal_to: 8)
    |> validate_number(:early_submission_xp, greater_than_or_equal_to: 0)
    |> validate_number(:hours_before_early_xp_decay, greater_than_or_equal_to: 0)
    |> unique_constraint([:order, :course_id])
  end
end
