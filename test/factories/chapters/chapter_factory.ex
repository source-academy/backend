defmodule Cadet.Chapters.ChapterFactory do
  @moduledoc """
  Factory for Chapter entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Chapters.Chapter

      def chapter_factory do
        %Chapter{
          chapterno: 1,
          variant: "default"
        }
      end
    end
  end
end
