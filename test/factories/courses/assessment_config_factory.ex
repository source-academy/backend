defmodule Cadet.Courses.AssessmentConfigFactory do
  @moduledoc """
  Factory for the AssessmentConfig entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Courses.AssessmentConfig

      def assessment_config_factory do
        %AssessmentConfig{
          order: 1,
          type: Faker.Pokemon.En.name(),
          early_submission_xp: 200,
          hours_before_early_xp_decay: 48,
          course: build(:course)
        }
      end
    end
  end
end
