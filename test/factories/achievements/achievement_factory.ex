defmodule Cadet.Incentives.AchievementFactory do
  @moduledoc """
  Factory for the Achievement entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Incentives.Achievement
      alias Ecto.UUID

      def achievement_factory do
        %Achievement{
          uuid: UUID.generate(),
          title: Faker.Food.dish(),
          ability: Enum.random(Achievement.valid_abilities()),
          is_task: false,
          position: 0,
          description: Faker.Lorem.Shakespeare.En.king_richard_iii(),
          completion_text: Faker.Lorem.Shakespeare.En.romeo_and_juliet(),
          canvas_url:
            "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/canvas/annotated-canvas.png"
        }
      end
    end
  end
end
