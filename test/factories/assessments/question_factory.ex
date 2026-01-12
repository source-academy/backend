defmodule Cadet.Assessments.QuestionFactory do
  @moduledoc """
  Factories for the Question entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Question

      def question_factory do
        Enum.random([build(:programming_question), build(:mcq_question), build(:voting_question)])
      end

      def programming_question_factory do
        library = build(:library)

        %Question{
          type: :programming,
          max_xp: 100,
          assessment: build(:assessment, %{is_published: true}),
          library: library,
          grading_library: Enum.random([build(:library), library]),
          question: build(:programming_question_content)
        }
      end

      def programming_question_content_factory do
        %{
          prepend: Faker.Pokemon.location(),
          content: Faker.Pokemon.name(),
          postpend: Faker.Pokemon.location(),
          template: Faker.Lorem.Shakespeare.as_you_like_it(),
          solution: Faker.Lorem.Shakespeare.hamlet(),
          public: [
            %{
              score: :rand.uniform(5),
              answer: Faker.StarWars.character(),
              program: Faker.Lorem.Shakespeare.king_richard_iii()
            }
          ],
          opaque: [
            %{
              score: :rand.uniform(5),
              answer: Faker.StarWars.character(),
              program: Faker.Lorem.Shakespeare.king_richard_iii()
            }
          ],
          secret: [
            %{
              score: :rand.uniform(5),
              answer: Faker.StarWars.character(),
              program: Faker.Lorem.Shakespeare.king_richard_iii()
            }
          ],
          llm_prompt: nil
        }
      end

      def mcq_question_factory do
        library = build(:library)

        %Question{
          type: :mcq,
          max_xp: 100,
          assessment: build(:assessment, %{is_published: true}),
          library: build(:library),
          grading_library: Enum.random([build(:library), library]),
          question: %{
            content: Faker.Pokemon.name(),
            choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
          }
        }
      end

      def mcq_choice_factory do
        %{
          content: Faker.Pokemon.name(),
          hint: Faker.Pokemon.location()
        }
      end

      def voting_question_factory do
        library = build(:library)
        contest_assessment = insert(:assessment, %{is_published: true})

        %Question{
          type: :voting,
          max_xp: 100,
          assessment: build(:assessment, %{is_published: true}),
          library: build(:library),
          grading_library: Enum.random([build(:library), library]),
          question: %{
            content: Faker.Pokemon.name(),
            prepend: Faker.Pokemon.location(),
            template: Faker.Lorem.Shakespeare.as_you_like_it(),
            contest_number: contest_assessment.number,
            reveal_hours: 48,
            token_divider: 50,
            xp_values: [500, 400, 300]
          }
        }
      end

      def voting_question_content_factory do
        contest_assessment = insert(:assessment, %{is_published: true})

        %{
          content: Faker.Pokemon.name(),
          prepend: Faker.Pokemon.location(),
          template: Faker.Lorem.Shakespeare.as_you_like_it(),
          contest_number: contest_assessment.number,
          reveal_hours: 48,
          token_divider: 50,
          xp_values: [500, 400, 300]
        }
      end
    end
  end
end
