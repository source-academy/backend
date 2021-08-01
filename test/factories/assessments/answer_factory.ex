defmodule Cadet.Assessments.AnswerFactory do
  @moduledoc """
  Factory for the Answer entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Answer

      def answer_factory do
        %Answer{
          answer: %{},
          autograding_status: :none,
          comments: Faker.Food.dish()
        }
      end

      def programming_answer_factory do
        %{
          code: sequence(:code, &"return #{&1};")
        }
      end

      def mcq_answer_factory do
        %{
          choice_id: Enum.random(0..2)
        }
      end

      def voting_answer_factory do
        %{
          completed: Enum.random(0..1) == 1
        }
      end
    end
  end
end
