defmodule Cadet.AICommentsTest do
  use Cadet.DataCase

  alias Cadet.{AIComments, Repo}
  alias Cadet.AIComments.AICommentVersion
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    course = insert(:course)
    assessment = insert(:assessment, course: course)
    submission = insert(:submission, assessment: assessment)
    question = insert(:programming_question, assessment: assessment)
    answer = insert(:answer, submission: submission, question: question)
    editor = insert(:user)

    {:ok, ai_comment} =
      AIComments.create_ai_comment(%{
        answer_id: answer.id,
        raw_prompt: "prompt",
        answers_json: "[]"
      })

    {:ok, ai_comment: ai_comment, editor: editor}
  end

  test "creates distinct version numbers for concurrent edits", %{ai_comment: ai_comment, editor: editor} do
    parent = self()

    create_version = fn content ->
      Sandbox.allow(Repo, parent, self())
      AIComments.create_comment_version(ai_comment.id, 0, content, editor.id)
    end

    task_1 = Task.async(fn -> create_version.("first edit") end)
    task_2 = Task.async(fn -> create_version.("second edit") end)

    assert {:ok, _} = Task.await(task_1, 5_000)
    assert {:ok, _} = Task.await(task_2, 5_000)

    versions =
      Repo.all(
        from(v in AICommentVersion,
          where: v.ai_comment_id == ^ai_comment.id and v.comment_index == 0,
          order_by: [asc: v.version_number]
        )
      )

    assert Enum.map(versions, & &1.version_number) == [1, 2]
    assert Enum.sort(Enum.map(versions, & &1.content)) == ["first edit", "second edit"]
  end
end
