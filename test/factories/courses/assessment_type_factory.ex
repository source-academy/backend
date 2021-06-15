defmodule Cadet.Courses.AssessmentTypeFactory do
  @moduledoc """
  Factory for the AssessmentType entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Courses.AssessmentType

      def assessment_type_factory do
        %AssessmentType{
          order: 1,
          type: "Missions",
          course: build(:course)
        }
      end
    end
  end
end
