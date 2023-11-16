defmodule Cadet.Assessments.QuestionTypes.VotingQuestionTest do
  alias Cadet.Assessments.QuestionTypes.VotingQuestion

  use Cadet.ChangesetCase, entity: VotingQuestion

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          content: "content",
          contest_number: "C4",
          reveal_hours: 48,
          token_divider: 50
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

      assert_changeset(
        %{
          content: "content",
          contest_number: "C3",
          reveal_hours: 48,
          token_divider: -1
        },
        :invalid
      )

      assert_changeset(
        %{
          content: "content",
          contest_number: "C6",
          reveal_hours: 48,
          token_divider: 0
        },
        :invalid
      )
    end
  end
end
