defmodule Cadet.Achievements.AchievementPrerequisiteFactory do
  @moduledoc """
  Factory for the AchievementPrerequisite entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Achievements.AchievementPrerequisite

      def achievement_prerequisite_factory do
        %AchievementPrerequisite{}
      end
    end
  end
end
