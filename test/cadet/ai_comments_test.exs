defmodule Cadet.AICommentsTest do
  use Cadet.DataCase

  alias Cadet.AIComments

  defp insert_answer do
    assessment = insert(:assessment, %{is_published: true})
    student = insert(:course_registration, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})
    question = insert(:programming_question, %{assessment: assessment})

    insert(:answer, %{submission: submission, question: question})
  end

  defp insert_comment(attrs) do
    answer = insert_answer()

    {:ok, comment} =
      AIComments.create_ai_comment(
        Map.merge(
          %{answer_id: answer.id, raw_prompt: "prompt", answers_json: "[]"},
          attrs
        )
      )

    {answer, comment}
  end

  describe "get_ai_comment/1" do
    test "returns the comment" do
      {_answer, comment} = insert_comment(%{})

      assert {:ok, %{id: id}} = AIComments.get_ai_comment(comment.id)
      assert id == comment.id
    end

    test "returns :not_found for an unknown id" do
      assert {:error, :not_found} = AIComments.get_ai_comment(0)
    end
  end

  describe "get_latest_ai_comment/1" do
    test "returns nil when the answer has no comment log" do
      answer = insert_answer()

      assert AIComments.get_latest_ai_comment(answer.id) == nil
    end
  end

  describe "update_ai_comment/2" do
    test "updates the log entry" do
      {_answer, comment} = insert_comment(%{})

      assert {:ok, updated} = AIComments.update_ai_comment(comment.id, %{response: "A response"})
      assert updated.response == "A response"
    end

    test "returns :not_found for an unknown id" do
      assert {:error, :not_found} = AIComments.update_ai_comment(0, %{response: "A response"})
    end
  end

  describe "update_final_comment/2" do
    test "writes the final comment onto the latest log entry" do
      {answer, comment} = insert_comment(%{})

      assert {:ok, updated} = AIComments.update_final_comment(answer.id, "Looks good.")
      assert updated.id == comment.id
      assert updated.final_comment == "Looks good."
    end

    # A grader who never used AI-assisted commenting has no log row to attach the final comment
    # to. Treating that as an error surfaced as a 422 when they saved an ordinary grade, so the
    # absence is a no-op success instead.
    test "is a no-op success when the answer has no AI comment log" do
      answer = insert_answer()

      assert {:ok, nil} = AIComments.update_final_comment(answer.id, "Looks good.")
    end
  end
end
