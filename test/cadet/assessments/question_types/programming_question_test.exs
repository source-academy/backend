defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestionTest do
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  use Cadet.ChangesetCase, entity: ProgrammingQuestion

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          content: "asd",
          template: "asd"
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(
        %{
          content: 1,
          template: "asd"
        },
        :invalid
      )

      assert_changeset(
        %{
          content: "asd"
        },
        :invalid
      )
    end
  end
end
