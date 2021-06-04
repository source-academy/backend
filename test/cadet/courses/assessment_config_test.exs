defmodule Cadet.Courses.AssessmentConfigTest do
  alias Cadet.Courses.AssessmentConfig

  use Cadet.ChangesetCase, entity: AssessmentConfig

  describe "Assessment Configuration Changesets" do
    test "valid changesets" do
      assert_changeset(
        %{
          early_submission_xp: 200,
          hours_before_early_xp_decay: 48,
          decay_rate_points_per_hour: 1
        },
        :valid
      )

      assert_changeset(
        %{
          early_submission_xp: 0,
          hours_before_early_xp_decay: 0,
          decay_rate_points_per_hour: 0
        },
        :valid
      )

      assert_changeset(
        %{
          early_submission_xp: 200,
          hours_before_early_xp_decay: 0,
          decay_rate_points_per_hour: 10
        },
        :valid
      )
    end

    test "invalid changeset missing required params" do
      assert_changeset(
        %{
          early_submission_xp: 0,
          hours_before_early_xp_decay: 0
        },
        :invalid
      )

      assert_changeset(
        %{
          early_submission_xp: 0
        },
        :invalid
      )

      assert_changeset(
        %{
          decay_rate_points_per_hour: 1
        },
        :invalid
      )
    end

    test "invalid changeset with invalid early xp" do
      assert_changeset(
        %{
          early_submission_xp: -1,
          hours_before_early_xp_decay: 0,
          decay_rate_points_per_hour: 10
        },
        :invalid
      )
    end

    test "invalid changeset with invalid hours before decay" do
      assert_changeset(
        %{
          early_submission_xp: 200,
          hours_before_early_xp_decay: -1,
          decay_rate_points_per_hour: 10
        },
        :invalid
      )
    end

    test "invalid changeset with invalid decay rate" do
      assert_changeset(
        %{
          early_submission_xp: 200,
          hours_before_early_xp_decay: 0,
          decay_rate_points_per_hour: -1
        },
        :invalid
      )
    end

    test "invalid changeset with decay rate greater than early submission xp" do
      assert_changeset(
        %{
          early_submission_xp: 200,
          hours_before_early_xp_decay: 48,
          decay_rate_points_per_hour: 300
        },
        :invalid
      )
    end
  end
end
