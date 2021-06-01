defmodule Cadet.Courses.AssessmentTypes do
  @moduledoc """
  The AssessmentType entity stores the assessment tyoes in a
  particular course.
  """
  use Cadet, :model

  alias Cadet.Courses.Course

  schema "assessment_types" do
    field(:order, :integer)
    field(:type, :string)
    belongs_to(:course, Course)

    timestamps()
  end

  @required_fields ~w(order type course)a

  def changeset(assessment_type, params) do
    assessment_type
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
