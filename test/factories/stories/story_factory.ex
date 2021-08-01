defmodule Cadet.Stories.StoryFactory do
  @moduledoc """
  Factory for the Story entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Stories.Story

      def story_factory do
        %Story{
          open_at: Timex.shift(Timex.now(), days: 1),
          close_at: Timex.shift(Timex.now(), days: Enum.random(2..30)),
          is_published: false,
          filenames: ["mission-1.txt"],
          title: "Mission1",
          image_url: "http://example.com",
          course: build(:course)
        }
      end
    end
  end
end
