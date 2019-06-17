defmodule Cadet.Assessments.AnswerFactory do
  @moduledoc """
  Factory for the Answer entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Assessments.Answer

      def answer_factory do
        valid_autograding_results = [
          [
            %{
              "resultType" => "pass",
              "score" => 1
            },
            %{
              "resultType" => "pass",
              "score" => 1
            },
            %{
              "resultType" => "pass",
              "score" => 1
            }
          ],
          [
            %{
              "resultType" => "fail",
              "expected" => "1",
              "actual" => "2"
            },
            %{
              "resultType" => "fail",
              "expected" => "2",
              "actual" => "3"
            },
            %{
              "resultType" => "fail",
              "expected" => "5",
              "actual" => "8"
            }
          ],
          [
            %{
              "resultType" => "error",
              "errors" => [
                %{
                  "errorType" => "syntax",
                  "line" => 1,
                  "location" => "student",
                  "errorLine" => "const f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2)",
                  "errorExplanation" => "Missing semicolon at the end of statement"
                }
              ]
            },
            %{
              "resultType" => "error",
              "errors" => [
                %{
                  "errorType" => "syntax",
                  "line" => 1,
                  "location" => "student",
                  "errorLine" => "const f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2)",
                  "errorExplanation" => "Missing semicolon at the end of statement"
                }
              ]
            },
            %{
              "resultType" => "error",
              "errors" => [
                %{
                  "errorType" => "syntax",
                  "line" => 1,
                  "location" => "student",
                  "errorLine" => "const f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2)",
                  "errorExplanation" => "Missing semicolon at the end of statement"
                }
              ]
            }
          ]
        ]

        %Answer{
          answer: %{},
          autograding_results: sequence(:map, valid_autograding_results),
          autograding_status: :none,
          comment: Faker.Lorem.Shakespeare.En.romeo_and_juliet()
        }
      end

      def programming_answer_factory do
        %{
          code: sequence(:code, &"alert(#{&1})")
        }
      end

      def mcq_answer_factory do
        %{
          choice_id: Enum.random(0..2)
        }
      end
    end
  end
end
