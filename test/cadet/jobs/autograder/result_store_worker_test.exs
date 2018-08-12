defmodule Cadet.Autograder.ResultStoreWorkerTest do
  use Cadet.DataCase

  import ExUnit.CaptureLog

  alias Cadet.Assessments.Answer
  alias Cadet.Autograder.ResultStoreWorker

  setup do
    answer = insert(:answer, %{question: insert(:question), submission: insert(:submission)})
    success_no_errors = %{status: :success, grade: 10, errors: []}

    success_with_errors = %{
      errors: [
        %{
          errors: [%{"errorType" => "syntax", "line" => 1, "location" => "student"}],
          grader_program:
            "function ek0chei0y1() {\n    return f(0) === 0 ? 1 : 0;\n  }\n\n  ek0chei0y1();"
        },
        %{
          errors: [%{"errorType" => "syntax", "line" => 1, "location" => "student"}],
          grader_program:
            "function ek0chei0y1() {\n    const test1 = f(7) === 13;\n    const test2 = f(10) === 55;\n    const test3 = f(12) === 144;\n    return test1 && test2 && test3 ? 4 : 0;\n  }\n\n  ek0chei0y1();"
        }
      ],
      grade: 0,
      status: :success
    }

    failed = %{
      errors: [
        %{
          "systemError" => "Autograder runtime error. Please contact a system administrator"
        }
      ],
      grade: 0,
      status: :failed
    }

    %{answer: answer, results: [success_no_errors, success_with_errors, failed]}
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

        answer = Repo.get(Answer, answer.id)

        errors_string_keys =
          Enum.map(result.errors, fn err ->
            Enum.reduce(err, %{}, fn {k, v}, acc ->
              Map.put(acc, "#{k}", v)
            end)
          end)

        assert answer.grade == result.grade
        assert answer.autograding_status == result.status
        assert answer.autograding_errors == errors_string_keys
      end
    end
  end
end
