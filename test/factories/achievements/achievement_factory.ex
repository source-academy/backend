defmodule Cadet.Achievements.AchievementFactory do
  @moduledoc """
  Factory for the Achievement entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Achievements.Achievement

      def achievement_factory do
        %Achievement{
          title: Faker.Food.dish(), 
          background_image_url: "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
          modal_image_url: "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/locations/planet-y-orbit/crashing.png",
          description: Faker.Lorem.Shakespeare.En.king_richard_iii(),
          completion_text: Faker.Lorem.Shakespeare.En.romeo_and_juliet()
        }
      end
    end
  end
end
