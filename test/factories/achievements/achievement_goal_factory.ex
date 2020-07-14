defmodule Cadet.Achievements.AchievementGoalFactory do
  @moduledoc """
  Factory for the AchievementGoal entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Achievements.AchievementGoal

      def achievement_goal_factory do
        %AchievementGoal{

        }
      end
    end
  end
end
