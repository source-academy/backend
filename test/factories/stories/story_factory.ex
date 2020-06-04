defmodule Cadet.Stories.StoryFactory do
  @moduledoc """
  Factory for the Story entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Stories.Story

      def story_factory do

        %Story{
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: Enum.random(1..30)),
          is_published: false
        }
      end
    end
  end
end
