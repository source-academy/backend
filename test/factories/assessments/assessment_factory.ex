defmodule Cadet.Assessments.AssessmentFactory do
  @moduledoc """
  Factory for the Assessment entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Assessment

      def assessment_factory do
        course = build(:course)
        config = build(:assessment_config, %{course: course})
        type_title = config.type

        # These are actual story identifiers so front-end can use seeds to test more effectively
        valid_stories = [
          "contest-7.1",
          "mission-19",
          "mission-1",
          "mission-7",
          "sidequest-2.1",
          "sidequest-9.1"
        ]

        %Assessment{
          title: Faker.Lorem.Shakespeare.En.hamlet(),
          cover_picture: Faker.Avatar.image_url(),
          summary_short: Faker.Lorem.Shakespeare.En.king_richard_iii(),
          summary_long: Faker.Lorem.Shakespeare.En.romeo_and_juliet(),
          number:
            sequence(
              :number,
              &"#{type_title |> String.first() |> String.upcase()}#{&1}"
            ),
          story: Enum.random(valid_stories),
          reading: Faker.Lorem.sentence(),
          config: config,
          course: course,
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: Enum.random(1..30)),
          is_published: false,
          max_team_size: 1,
          llm_assessment_prompt: nil
        }
      end
    end
  end
end
