defmodule Cadet.Assessments.QuestionFactory do
  @moduledoc """
  Factories for the Question entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Question

      def question_factory do
        Enum.random([build(:programming_question), build(:mcq_question)])
      end

      def programming_question_factory do
        %Question{
          type: :programming,
          max_grade: 10,
          assessment: build(:assessment, %{is_published: true}),
          library: build(:library),
          grading_library: Enum.random([build(:library), nil]),
          question: %{
            content: Faker.Pokemon.name(),
            solution_header: Faker.Pokemon.location(),
            solution_template: Faker.Lorem.Shakespeare.as_you_like_it(),
            solution: Faker.Lorem.Shakespeare.hamlet()
          }
        }
      end

      def mcq_question_factory do
        %Question{
          type: :mcq,
          max_grade: 10,
          assessment: build(:assessment, %{is_published: true}),
          library: build(:library),
          grading_library: Enum.random([build(:library), nil]),
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
    end
  end
end
