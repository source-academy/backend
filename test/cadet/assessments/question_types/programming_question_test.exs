defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestionTest do
  alias Cadet.Assessments.QuestionTypes.ProgrammingQuestion

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: ProgrammingQuestion

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(%{
        content: "asd",
        solution_template: "asd",
        solution: "asd",
        library: %{version: 1}
      })
    end

    test "invalid changesets" do
      assert_changeset(%{content: "asd"}, :invalid)

      assert_changeset(
        %{
          content: "asd",
          solution_template: "asd",
          solution_header: "asd",
          library: %{globals: ["a"]}
        },
        :invalid
      )
    end
  end
end
