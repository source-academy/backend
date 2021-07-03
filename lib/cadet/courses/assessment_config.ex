defmodule Cadet.Courses.AssessmentConfig do
  @moduledoc """
  The AssessmentConfig entity stores the assessment tyoes in a
  particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.Course

  schema "assessment_configs" do
    field(:order, :integer)
    field(:type, :string)
    field(:is_graded, :boolean, default: true)

    # a graded assessment type will not build solutions and private testcases as hidden to the frontend
    field(:skippable, :boolean, default: true)
    # only for frontend to determine if a student can go to next question without attempting
    field(:is_autograded, :boolean, default: true)
    # assessment will be autograded a day after due day
    field(:early_submission_xp, :integer, default: 0)
    field(:hours_before_early_xp_decay, :integer, default: 0)

    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(course_id)a
  @optional_fields ~w(order type early_submission_xp
    hours_before_early_xp_decay is_graded skippable is_autograded)a

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
