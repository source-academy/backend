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
    field(:early_submission_xp, :integer, default: 0)
    field(:hours_before_early_xp_decay, :integer, default: 0)
    field(:decay_rate_points_per_hour, :integer, default: 0)

    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(order course_id)a
  @optional_fields ~w(type early_submission_xp hours_before_early_xp_decay
    decay_rate_points_per_hour is_graded)a

  def changeset(assessment_config, params) do
    params = capitalize(params, :type)

    assessment_config
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:order, greater_than: 0)
    |> validate_number(:order, less_than_or_equal_to: 5)
    |> validate_number(:early_submission_xp, greater_than_or_equal_to: 0)
    |> validate_number(:hours_before_early_xp_decay, greater_than_or_equal_to: 0)
    |> validate_number(:decay_rate_points_per_hour, greater_than_or_equal_to: 0)
    |> validate_decay_rate()
    |> unique_constraint([:type, :course_id])
    |> unique_constraint([:order, :course_id])
  end

  defp capitalize(params, field) do
    Map.update(params, field, nil, &String.capitalize/1)
  end

  defp validate_decay_rate(changeset) do
    changeset
    |> validate_number(:decay_rate_points_per_hour,
      less_than_or_equal_to: get_field(changeset, :early_submission_xp)
    )
  end
end
