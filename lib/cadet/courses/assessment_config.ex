defmodule Cadet.Courses.AssessmentConfig do
  @moduledoc """
  The AssessmentConfig entity stores the assessment configuration
  of a particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.Course

  schema "assessment_configs" do
    field(:early_submission_xp, :integer, default: 200)
    field(:days_before_early_xp_decay, :integer, default: 2)
    field(:decay_rate_points_per_hour, :integer, default: 1)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(course)a
  @optional_fields ~w(early_submission_xp days_before_early_xp_decay
    decay_rate_points_per_hour)a

  def changeset(assessment_config, params) do
    assessment_config
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
