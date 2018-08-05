defmodule Cadet.Autograder.ResultStoreWorkerTest do
  use Cadet.DataCase

  import ExUnit.CaptureLog

  alias Cadet.Assessments.Answer
  alias Cadet.Autograder.ResultStoreWorker

  setup do
    answer = insert(:answer, %{question: insert(:question), submission: insert(:submission)})
    success = %{status: :success, grade: 10}
    failed = %{status: :failed}
    %{answer: answer, success: success, failed: failed}
  end

  describe "#perform, invalid answer_id" do
    test "it captures log", %{failed: success} do
      log =
        capture_log(fn ->
          ResultStoreWorker.perform(%{answer_id: 432_569, result: success})
        end)

      assert log =~ "Failed to store autograder result. answer_id: 432569"
    end
  end

  describe "#perform, valid answer_id" do
    test "it updates successful result correctly", %{answer: answer, success: success} do
      ResultStoreWorker.perform(%{answer_id: answer.id, result: success})
      answer = Repo.get(Answer, answer.id)
      assert answer.grade == success.grade
      assert answer.autograding_status == :success
    end

    test "it updates failed result correctly", %{answer: answer, failed: failed} do
      ResultStoreWorker.perform(%{answer_id: answer.id, result: failed})
      answer = Repo.get(Answer, answer.id)
      assert answer.autograding_status == :failed

      # Default value of grade is 0
      assert answer.grade == 0
    end
  end
end
