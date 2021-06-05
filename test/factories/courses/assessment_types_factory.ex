defmodule Cadet.Courses.AssessmentTypesFactory do
  @moduledoc """
  Factory for the AssessmentTypes entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Courses.AssessmentTypes

      def assessment_types_factory do
        %AssessmentTypes{
          order: 1,
          type: "Missions"
          # course: build(:course)
        }
      end
    end
  end
end
