defmodule Cadet.Assessments.QuestionTypes.MCQQuestionTest do
  alias Cadet.Assessments.QuestionTypes.MCQQuestion

  use Cadet.ChangesetCase, entity: MCQQuestion

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          content: "asd",
          choices: [%{choice_id: 1, content: "asd", is_correct: true}]
        },
        :valid
      )
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
