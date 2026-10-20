defmodule Cadet.Autograder.LambdaWorkerTest do
  use Cadet.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Oban.Testing, repo: Cadet.Repo

  import ExUnit.CaptureLog
  import Mock
  import Oban.Testing, only: [with_testing_mode: 2]

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
        with_testing_mode(:manual, fn ->
          LambdaWorker.perform(%Oban.Job{
            args: %{
              "question_id" => question.id,
              "answer_id" => answer.id,
              "overwrite" => true
            }
          })

          assert_enqueued(
            worker: ResultStoreWorker,
            args: %{
              answer_id: answer.id,
              result: %{
                result: [
                  %{"resultType" => "pass", "score" => 1},
                  %{"resultType" => "pass", "score" => 1}
                ],
                score: 2,
                max_score: 2,
                status: :success
              },
              overwrite: true
            }
          )
        end)
      end
    end

    test "submission errors", %{question: question, answer: answer} do
      use_cassette "autograder/errors#1", custom: true do
        with_testing_mode(:manual, fn ->
          LambdaWorker.perform(%{
            question_id: question.id,
            answer_id: answer.id
          })

          assert_enqueued(
            worker: ResultStoreWorker,
            args: %{
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
            }
          )
        end)
      end
    end

    test "lambda errors", %{question: question, answer: answer} do
      use_cassette "autograder/errors#2", custom: true do
        with_testing_mode(:manual, fn ->
          LambdaWorker.perform(%{
            question_id: question.id,
            answer_id: answer.id
          })

          assert_enqueued(
            worker: ResultStoreWorker,
            args: %{
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
            }
          )
        end)
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
            question_id: question.id,
            answer_id: answer.id
          })
        end)

      assert log =~ "No testcases found. Skipping autograding for answer_id: #{answer.id}"
    end
  end

  describe "failure handling" do
    test "enqueues a failed result when the Lambda request raises", %{
      question: question,
      answer: answer
    } do
      with_testing_mode(:manual, fn ->
        with_mock ExAws, [:passthrough],
          request!: fn _request -> raise "Lambda unavailable" end do
          log =
            capture_log(fn ->
              assert {:error, _} =
                       LambdaWorker.perform(%Oban.Job{
                         args: %{
                           "question_id" => question.id,
                           "answer_id" => answer.id,
                           "overwrite" => true
                         }
                       })
            end)

          assert log =~ "Failed to get autograder result. answer_id: #{answer.id}"
          assert log =~ "Lambda unavailable"

          assert_enqueued(
            worker: ResultStoreWorker,
            args: %{
              answer_id: answer.id,
              overwrite: true,
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
        end
      end)
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
          globals: Enum.map(question.grading_library.globals, fn {k, v} -> [k, v] end),
          runtime: question.grading_library.runtime
        }
      }

      assert LambdaWorker.build_request_params(%{
               question: Repo.get(Question, question.id),
               answer: Repo.get(Answer, answer.id)
             }) == expected
    end

    test "it passes the python runtime through to the grader", %{answer: answer} do
      question =
        insert(:programming_question, %{grading_library: build(:library, %{runtime: "python"})})

      params =
        LambdaWorker.build_request_params(%{
          question: Repo.get(Question, question.id),
          answer: Repo.get(Answer, answer.id)
        })

      assert params.library.runtime == "python"
    end
  end

  describe "runtime routing" do
    setup %{answer: answer} do
      python_question =
        insert(:programming_question, %{
          grading_library: build(:library, %{runtime: "python"}),
          question:
            build(:programming_question_content, %{
              public: [%{"score" => 1, "answer" => "1", "program" => "f(1);"}],
              opaque: [],
              secret: []
            })
        })

      python_answer =
        insert(:answer, %{
          submission:
            insert(:submission, %{
              student: insert(:course_registration, %{role: :student}),
              assessment: python_question.assessment
            }),
          question: python_question,
          answer: %{code: "1"}
        })

      %{python_question: python_question, python_answer: python_answer, answer: answer}
    end

    test "python questions invoke the configured python lambda", %{python_answer: python_answer} do
      with_testing_mode(:manual, fn ->
        with_mocks [
          {ExAws.Lambda, [:passthrough],
           invoke: fn lambda_name, _params, _opts ->
             send(self(), {:invoked_lambda, lambda_name})
             %{stub: lambda_name}
           end},
          {ExAws, [:passthrough],
           request!: fn _request -> %{"totalScore" => 0, "maxScore" => 0, "results" => []} end}
        ] do
          LambdaWorker.perform(%{
            question_id: python_answer.question_id,
            answer_id: python_answer.id
          })

          assert_received {:invoked_lambda, "dummy-python"}
        end
      end)
    end

    test "python questions fail gracefully when no python lambda is configured", %{
      python_answer: python_answer
    } do
      original = Application.fetch_env!(:cadet, :autograder)
      on_exit(fn -> Application.put_env(:cadet, :autograder, original) end)
      Application.put_env(:cadet, :autograder, Keyword.delete(original, :python_lambda_name))

      with_testing_mode(:manual, fn ->
        log =
          capture_log(fn ->
            assert {:error, _} =
                     LambdaWorker.perform(%Oban.Job{
                       args: %{
                         "question_id" => python_answer.question_id,
                         "answer_id" => python_answer.id
                       }
                     })
          end)

        assert log =~ "No autograder lambda configured for runtime \"python\""

        assert_enqueued(
          worker: ResultStoreWorker,
          args: %{
            answer_id: python_answer.id,
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
      end)
    end
  end
end
