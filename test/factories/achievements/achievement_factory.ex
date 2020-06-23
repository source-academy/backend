defmodule Cadet.Achievements.AchievementFactory do
  @moduledoc """
  Factory for the Answer entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Achievements.{Achievement, AchievementAbility}

      def achievement_factory do
        %Achievement {
          title: Faker.Food.dish()
        }
      end
    end
  end
end
