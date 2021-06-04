defmodule Cadet.Courses.AssessmentConfig do
  @moduledoc """
  The AssessmentConfig entity stores the assessment configuration
  of a particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.Course

  schema "assessment_configs" do
    field(:early_submission_xp, :integer)
    field(:hours_before_early_xp_decay, :integer)
    field(:decay_rate_points_per_hour, :integer)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(early_submission_xp hours_before_early_xp_decay
    decay_rate_points_per_hour)a

  def changeset(assessment_config, params) do
    assessment_config
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:course_id)
    |> validate_number(:early_submission_xp, greater_than_or_equal_to: 0)
    |> validate_number(:hours_before_early_xp_decay, greater_than_or_equal_to: 0)
    |> validate_number(:decay_rate_points_per_hour, greater_than_or_equal_to: 0)
    |> validate_decay_rate()
  end

  defp validate_decay_rate(changeset) do
    changeset
    |> validate_number(:decay_rate_points_per_hour,
      less_than_or_equal_to: get_field(changeset, :early_submission_xp)
    )
  end
end
