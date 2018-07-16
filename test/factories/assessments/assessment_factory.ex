defmodule Cadet.Assessments.AssessmentFactory do
  @moduledoc """
  Factory for the Assessment entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Assessment

      def assessment_factory do
        %Assessment{
          title: Faker.Lorem.Shakespeare.En.hamlet(),
          summary_short: Faker.Lorem.Shakespeare.En.king_richard_iii(),
          summary_long: Faker.Lorem.Shakespeare.En.romeo_and_juliet(),
          type: Enum.random([:mission, :sidequest, :contest, :path]),
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: Enum.random(1..30)),
          is_published: false
        }
      end
    end
  end
end
