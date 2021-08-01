defmodule Cadet.Courses.AssessmentConfigTest do
  alias Cadet.Courses.AssessmentConfig

  use Cadet.ChangesetCase, entity: AssessmentConfig

  describe "Assessment Configs Changesets" do
    test "valid changesets" do
      assert_changeset(%{order: 1, type: "Missions", course_id: 1}, :valid)
      assert_changeset(%{order: 2, type: "quests", course_id: 1}, :valid)
      assert_changeset(%{order: 3, type: "Paths", course_id: 1}, :valid)
      assert_changeset(%{order: 4, type: "contests", course_id: 1}, :valid)
      assert_changeset(%{order: 5, type: "Others", course_id: 1}, :valid)
    end

    test "invalid changeset missing required params" do
      assert_changeset(%{order: 1}, :invalid)
      assert_changeset(%{order: 1, type: "Missions"}, :invalid)
    end

    test "invalid changeset with invalid order" do
      assert_changeset(%{order: 0, type: "Missions", course_id: 1}, :invalid)
      assert_changeset(%{order: 9, type: "Missions", course_id: 1}, :invalid)
    end
  end

  describe "Configuration-related Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          order: 1,
          type: "Missions",
          course_id: 1,
          early_submission_xp: 200,
          hours_before_early_xp_decay: 48
        },
        :valid
      )

      assert_changeset(
        %{
          order: 1,
          type: "Missions",
          course_id: 1,
          early_submission_xp: 0,
          hours_before_early_xp_decay: 0
        },
        :valid
      )

      assert_changeset(
        %{
          order: 1,
          type: "Missions",
          course_id: 1,
          early_submission_xp: 200,
          hours_before_early_xp_decay: 0
        },
        :valid
      )
    end

    test "invalid changeset with invalid early xp" do
      assert_changeset(
        %{
          order: 1,
          type: "Missions",
          course_id: 1,
          early_submission_xp: -1,
          hours_before_early_xp_decay: 0
        },
        :invalid
      )
    end

    test "invalid changeset with invalid hours before decay" do
      assert_changeset(
        %{
          order: 1,
          type: "Missions",
          course_id: 1,
          early_submission_xp: 200,
          hours_before_early_xp_decay: -1
        },
        :invalid
      )
    end
  end
end
