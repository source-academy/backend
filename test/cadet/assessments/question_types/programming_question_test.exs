defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestionTest do
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  use Cadet.ChangesetCase, entity: ProgrammingQuestion

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          content: "asd",
          solution_template: "asd"
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(%{content: "asd"}, :invalid)

      assert_changeset(
        %{
          content: "asd"
        },
        :invalid
      )
    end
  end
end
