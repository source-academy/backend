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
    field(:build_solution, :boolean, default: false)
    # a graded assessment type will not build solutions to the frontend
    field(:build_hidden, :boolean, default: false)
    # backend will build public testcases with hidden private testcases and will build postpend.
    field(:is_contest, :boolean, default: false)
    field(:early_submission_xp, :integer, default: 0)
    field(:hours_before_early_xp_decay, :integer, default: 0)

    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(course_id)a
  @optional_fields ~w(order type early_submission_xp
    hours_before_early_xp_decay build_solution build_hidden is_contest)a

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
