defmodule Cadet.Assessments.QuestionTypes.VotingQuestionTest do
  alias Cadet.Assessments.QuestionTypes.VotingQuestion

  use Cadet.ChangesetCase, entity: VotingQuestion

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          content: "asd"
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(
        %{
          content: 1
        },
        :invalid
      )
    end
  end
end
