defmodule Cadet.Autograder.ResultStoreWorkerTest do
  use Cadet.DataCase

  import ExUnit.CaptureLog

  alias Cadet.Assessments.Answer
  alias Cadet.Autograder.ResultStoreWorker

  setup do
    answer = insert(:answer, %{question: insert(:question), submission: insert(:submission)})
    success_no_errors = %{status: :success, grade: 10, result: []}

    success_with_errors = %{
      result: [
        %{
          "resultType" => "error",
          "errors" => [
            %{
              "errorType" => "syntax",
              "line" => 1,
              "location" => "student",
              "errorLine" => "consst f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);",
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
              "errorLine" => "consst f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);",
              "errorExplanation" => "SyntaxError: Unexpected token (2:7)"
            }
          ]
        }
      ],
      grade: 0,
      status: :success
    }

    failed = %{
      result: [
        %{
          "systemError" => "Autograder runtime error. Please contact a system administrator"
        }
      ],
      grade: 0,
      status: :failed
    }

    %{answer: answer, results: [failed, success_with_errors, success_no_errors]}
  end

  describe "#perform, invalid answer_id" do
    test "it captures log", %{results: [success | _]} do
      log =
        capture_log(fn ->
          ResultStoreWorker.perform(%{answer_id: 432_569, result: success})
        end)

      assert log =~ "Failed to store autograder result. answer_id: 432569"
    end
  end

  describe "#perform, valid answer_id" do
    test "it updates result correctly", %{answer: answer, results: results} do
      for result <- results do
        ResultStoreWorker.perform(%{answer_id: answer.id, result: result})

        answer =
          Answer
          |> join(:inner, [a], q in assoc(a, :question))
          |> preload([_, q], question: q)
          |> Repo.get(answer.id)

        errors_string_keys =
          Enum.map(result.result, fn err ->
            Enum.reduce(err, %{}, fn {k, v}, acc ->
              Map.put(acc, "#{k}", v)
            end)
          end)

        assert answer.grade == result.grade

        if answer.question.max_grade == 0 do
          assert answer.xp == 0
        else
          assert answer.xp ==
                   Integer.floor_div(
                     answer.question.max_xp * answer.grade,
                     answer.question.max_grade
                   )
        end

        assert answer.autograding_status == result.status
        assert answer.autograding_results == errors_string_keys
      end
    end
  end
end
