defmodule Cadet.Incentives.AchievementFactory do
  @moduledoc """
  Factory for the Achievement entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Incentives.{Achievement, AchievementPrerequisite}
      alias Ecto.UUID

      def achievement_factory do
        %Achievement{
          uuid: UUID.generate(),
          course: insert(:course),
          title: Faker.Food.dish(),
          is_task: false,
          position: 0,
          xp: 0,
          is_variable_xp: false,
          description: Faker.Lorem.Shakespeare.En.king_richard_iii(),
          completion_text: Faker.Lorem.Shakespeare.En.romeo_and_juliet(),
          canvas_url:
            "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/canvas/annotated-canvas.png"
        }
      end

      def achievement_prerequisite_factory do
        %AchievementPrerequisite{}
      end
    end
  end
end
