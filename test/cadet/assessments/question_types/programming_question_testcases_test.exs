defmodule Cadet.Assessments.QuestionTypes.ProgrammingQuestionTestcaseTest do
  alias Cadet.Assessments.QuestionTypes.Testcase

  use Cadet.ChangesetCase, entity: Testcase

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          score: 1,
          answer: "asd",
          program: "asd"
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(
        %{
          score: -1,
          answer: "asd",
          program: "asd"
        },
        :invalid
      )

      assert_changeset(
        %{
          score: 1,
          answer: "asd"
        },
        :invalid
      )

      assert_changeset(
        %{
          answer: "asd",
          program: "asd"
        },
        :invalid
      )

      assert_changeset(
        %{
          score: 1,
          program: "asd"
        },
        :invalid
      )
    end
  end
end
