defmodule Cadet.Courses.SourcecastFactory do
  @moduledoc """
  Factory for Sourcecast entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Courses.Sourcecast

      def sourcecast_factory do
        %Sourcecast{
          title: Faker.StarWars.character(),
          description: Faker.StarWars.planet(),
          audio: build(:upload),
          playbackData: Faker.StarWars.planet(),
          uploader: build(:user)
        }
      end
    end
  end
end
