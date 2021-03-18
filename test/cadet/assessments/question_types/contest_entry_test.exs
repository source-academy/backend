defmodule Cadet.Assessments.QuestionTypes.ContestEntryTest do
  alias Cadet.Assessments.QuestionTypes.ContestEntry

  use Cadet.ChangesetCase, entity: ContestEntry

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          score: 1,
          answer: "asd",
          submission_id: 2
        },
        :valid
      )

      assert_changeset(
        %{
          answer: "asd",
          submission_id: 2
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(
        %{
          score: -1,
          answer: "asd"
        },
        :invalid
      )

      assert_changeset(
        %{
          score: 1,
          submission_id: 2
        },
        :invalid
      )

      assert_changeset(
        %{
          score: -1,
          answer: "asd",
          submission_id: 2
        },
        :invalid
      )
    end
  end
end
