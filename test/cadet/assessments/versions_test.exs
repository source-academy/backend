defmodule Cadet.Assessments.VersionsTest do
  alias Cadet.Assessments.Version

  use Cadet.ChangesetCase, entity: Version

  @required_fields [:content, :answer_id]

  setup do
    assessment = insert(:assessment, %{is_published: true})
    student = insert(:course_registration, %{role: :student})
    submission = insert(:submission, %{student: student, assessment: assessment})
    programming_question = insert(:programming_question, %{assessment: assessment})
    answer = insert(:answer, %{submission: submission, question: programming_question})

    valid_params = %{
      content: %{code: "console.log('v1');"},
      name: "version 1",
      # restored: false,
      answer_id: answer.id
    }

    {:ok, %{answer: answer, valid_params: valid_params}}
  end

  describe "changeset" do
    test "valid params", %{valid_params: valid_params} do
      assert_changeset(valid_params, :valid)
    end

    test "invalid changeset missing required params", %{valid_params: valid_params} do
      for field <- @required_fields do
        params_missing_field = Map.delete(valid_params, field)
        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid changeset foreign key constraint", %{valid_params: valid_params} do
      invalid_params = Map.put(valid_params, :answer_id, -1)
      assert_changeset_db(invalid_params, :invalid)
    end
  end
end
