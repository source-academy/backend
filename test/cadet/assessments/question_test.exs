defmodule Cadet.Assessments.QuestionTest do
  alias Cadet.Assessments.Question

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Question

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          display_order: 2,
          title: "question",
          question: %{},
          type: :programming,
          library: build(:library),
          assessment_id: 2
        },
        :valid
      )

      assert_changeset(
        %{
          display_order: 1,
          title: "mcq",
          question: %{},
          type: :mcq,
          library: build(:library),
          assessment_id: 2
        },
        :valid
      )

      assert_changeset(
        %{
          display_order: 5,
          title: "sample title",
          question: %{},
          type: :programming,
          library: build(:library),
          raw_question: Jason.encode!(%{question: "This is a sample json"}),
          assessment_id: 2
        },
        :valid
      )
    end

    test "invalid changesets" do
      assert_changeset(
        %{
          display_order: 2,
          title: "question",
          type: :programming
        },
        :invalid
      )

      assert_changeset(
        %{
          display_order: 2,
          question: %{},
          type: :mcq
        },
        :invalid
      )
    end
  end
end
