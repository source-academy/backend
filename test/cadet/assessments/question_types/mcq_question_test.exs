defmodule Cadet.Assessments.QuestionTypes.MCQQuestionTest do
  alias Cadet.Assessments.QuestionTypes.MCQQuestion

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: MCQQuestion

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{
        content: "asd",
        choices: [%{choice_id: 1, content: "asd", is_correct: true}]
      })
    end

    test "invalid changesets" do
      assert_changeset(%{content: "asd"}, :invalid)

      assert_changeset(
        %{content: "asd", choices: [%{choice_id: 2, content: "asd", is_correct: false}]},
        :invalid
      )
    end
  end
end
