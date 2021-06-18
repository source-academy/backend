defmodule Cadet.Courses.AssessmentType do
  @moduledoc """
  The AssessmentType entity stores the assessment tyoes in a
  particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.{Course, AssessmentConfig}

  schema "assessment_types" do
    field(:order, :integer)
    field(:type, :string)
    field(:is_graded, :boolean, default: true)

    belongs_to(:course, Course)
    has_one(:assessment_config, AssessmentConfig)

    timestamps()
  end

  @required_fields ~w(order type course_id is_graded)a

  def changeset(assessment_type, params) do
    params = capitalize(params, :type)

    assessment_type
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:order, greater_than: 0)
    |> validate_number(:order, less_than_or_equal_to: 5)
    |> unique_constraint([:type, :course_id])
    |> unique_constraint([:order, :course_id])
  end

  defp capitalize(params, field) do
    Map.update(params, field, nil, &String.capitalize/1)
  end
end
