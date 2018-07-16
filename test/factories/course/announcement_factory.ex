defmodule Cadet.Course.AnnouncementFactory do
  @moduledoc """
  Factory for Announcement entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Course.Announcement

      def announcement_factory do
        %Announcement{
          title: sequence(:title, &"Announcement #{&1}") <> Faker.Company.catch_phrase(),
          content: Faker.StarWars.quote(),
          poster: build(:user)
        }
      end
    end
  end
end
