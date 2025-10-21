defmodule Cadet.Courses.CourseFactory do
  @moduledoc """
  Factory for the Course entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Courses.Course

      def course_factory do
        %Course{
          course_name: "Programming Methodology",
          course_short_name: "CS1101S",
          viewable: true,
          enable_game: true,
          enable_achievements: true,
          enable_sourcecast: true,
          enable_stories: false,
          source_chapter: 1,
          source_variant: "default",
          module_help_text: "Help Text",
          enable_llm_grading: false
        }
      end
    end
  end
end
