defmodule Cadet.Autograder.LambdaWorkerTest do
  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Mock
  import ExUnit.CaptureLog

  alias Cadet.Assessments.{Answer, Question}
  alias Cadet.Autograder.{LambdaWorker, ResultStoreWorker}

  setup_all do
    # This essentially does :application.ensure_all_started(:hackney)
    HTTPoison.start()
  end

  setup do
    question =
      insert(
        :programming_question,
        %{
          question:
            build(:programming_question_content, %{
              public: [
                %{"score" => 1, "answer" => "1", "program" => "f(1);"}
              ],
              opaque: [
                %{"score" => 1, "answer" => "45", "program" => "f(10);"}
              ],
              secret: [
                %{"score" => 1, "answer" => "45", "program" => "f(10);"}
              ]
            })
        }
      )

    submission =
      insert(:submission, %{
        student: insert(:course_registration, %{role: :student}),
        assessment: question.assessment
      })

    answer =
      insert(:answer, %{
        submission: submission,
        question: question,
        answer: %{code: "const f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);"}
      })

    %{question: question, answer: answer}
  end

  describe "#perform" do
    test "success", %{question: question, answer: answer} do
      use_cassette "autograder/success#1", custom: true do
        with_mock Que, add: fn _, _ -> nil end do
          LambdaWorker.perform(%{
            question: Repo.get(Question, question.id),
            answer: Repo.get(Answer, answer.id)
          })

          assert_called(
            Que.add(ResultStoreWorker, %{
              answer_id: answer.id,
              result: %{
                result: [
                  %{"resultType" => "pass", "score" => 1},
                  %{"resultType" => "pass", "score" => 1}
                ],
                score: 2,
                max_score: 2,
                status: :success
              }
            })
          )
        end
      end
    end

    test "submission errors", %{question: question, answer: answer} do
      use_cassette "autograder/errors#1", custom: true do
        with_mock Que, add: fn _, _ -> nil end do
          LambdaWorker.perform(%{
            question: Repo.get(Question, question.id),
            answer: Repo.get(Answer, answer.id)
          })

          assert_called(
            Que.add(ResultStoreWorker, %{
              answer_id: answer.id,
              result: %{
                result: [
                  %{
                    "resultType" => "error",
                    "errors" => [
                      %{
                        "errorType" => "syntax",
                        "line" => 1,
                        "location" => "student",
                        "errorLine" =>
                          "consst f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);",
                        "errorExplanation" => "SyntaxError: Unexpected token (2:7)"
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
                        "errorLine" =>
                          "consst f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);",
                        "errorExplanation" => "SyntaxError: Unexpected token (2:7)"
                      }
                    ]
                  }
                ],
                score: 0,
                max_score: 2,
                status: :success
              }
            })
          )
        end
      end
    end

    test "lambda errors", %{question: question, answer: answer} do
      use_cassette "autograder/errors#2", custom: true do
        with_mock Que, add: fn _, _ -> nil end do
          LambdaWorker.perform(%{
            question: Repo.get(Question, question.id),
            answer: Repo.get(Answer, answer.id)
          })

          assert_called(
            Que.add(ResultStoreWorker, %{
              answer_id: answer.id,
              result: %{
                score: 0,
                max_score: 1,
                status: :failed,
                result: [
                  %{
                    "resultType" => "error",
                    "errors" => [
                      %{
                        "errorType" => "systemError",
                        "errorMessage" =>
                          "2019-05-18T05:26:11.299Z 21606396-02e0-4fd5-a294-963bb7994e75 Task timed out after 10.01 seconds"
                      }
                    ]
                  }
                ]
              }
            })
          )
        end
      end
    end

    test "should not run with no testcases", %{answer: answer} do
      question =
        insert(
          :programming_question,
          %{
            question:
              build(:programming_question_content, %{
                public: [],
                opaque: [],
                secret: []
              })
          }
        )

      log =
        capture_log(fn ->
          LambdaWorker.perform(%{
            question: Repo.get(Question, question.id),
            answer: Repo.get(Answer, answer.id)
          })
        end)

      assert log =~ "No testcases found. Skipping autograding for answer_id: #{answer.id}"
    end
  end

  describe "on_failure" do
    test "it stores error message", %{question: question, answer: answer} do
      with_mock Que, add: fn _, _ -> nil end do
        error = %{"errorMessage" => "Task timed out after 1.00 seconds"}

        log =
          capture_log(fn ->
            LambdaWorker.on_failure(
              %{question: question, answer: answer},
              inspect(error)
            )
          end)

        assert log =~ "Failed to get autograder result."
        assert log =~ "answer_id: #{answer.id}"
        assert log =~ "Task timed out after 1.00 seconds"

        assert_called(
          Que.add(
            ResultStoreWorker,
            %{
              answer_id: answer.id,
              result: %{
                score: 0,
                max_score: 1,
                status: :failed,
                result: [
                  %{
                    "resultType" => "error",
                    "errors" => [
                      %{
                        "errorType" => "systemError",
                        "errorMessage" =>
                          "Autograder runtime error. Please contact a system administrator"
                      }
                    ]
                  }
                ]
              }
            }
          )
        )
      end
    end
  end

  describe "#build_request_params" do
    test "it should build correct params", %{question: question, answer: answer} do
      expected = %{
        prependProgram: question.question.prepend,
        postpendProgram: question.question.postpend,
        testcases:
          question.question.public ++ question.question.opaque ++ question.question.secret,
        studentProgram: answer.answer.code,
        library: %{
          chapter: question.grading_library.chapter,
          external: %{
            name: question.grading_library.external.name |> String.upcase(),
            symbols: question.grading_library.external.symbols
          },
          globals: Enum.map(question.grading_library.globals, fn {k, v} -> [k, v] end)
        }
      }

      assert LambdaWorker.build_request_params(%{
               question: Repo.get(Question, question.id),
               answer: Repo.get(Answer, answer.id)
             }) == expected
    end
  end
end
