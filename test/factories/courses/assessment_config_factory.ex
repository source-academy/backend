defmodule Cadet.Courses.AssessmentConfigFactory do
  @moduledoc """
  Factory for the AssessmentConfig entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Courses.AssessmentConfig

      def assessment_config_factory do
        %AssessmentConfig{
          early_submission_xp: 200,
          hours_before_early_xp_decay: 48,
          decay_rate_points_per_hour: 1
          # course: build(:course)
        }
      end
    end
  end
end
