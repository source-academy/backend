defmodule Cadet.Courses.AssessmentTypeTest do
  alias Cadet.Courses.AssessmentType

  use Cadet.ChangesetCase, entity: AssessmentType

  describe "Assessment Types Changesets" do
    test "valid changesets" do
      assert_changeset(%{order: 1, type: "Missions", course_id: 1}, :valid)
      assert_changeset(%{order: 2, type: "quests", course_id: 1}, :valid)
      assert_changeset(%{order: 3, type: "Paths", course_id: 1}, :valid)
      assert_changeset(%{order: 4, type: "contests", course_id: 1}, :valid)
      assert_changeset(%{order: 5, type: "Others", course_id: 1}, :valid)
    end

    test "invalid changeset missing required params" do
      assert_changeset(%{order: 1}, :invalid)
      assert_changeset(%{type: "Missions"}, :invalid)
      assert_changeset(%{course_id: 1}, :invalid)
      assert_changeset(%{order: 1, type: "Missions"}, :invalid)
      assert_changeset(%{order: 1, course_id: 1}, :invalid)
    end

    test "invalid changeset with invalid order" do
      assert_changeset(%{order: 0, type: "Missions", course_id: 1}, :invalid)
      assert_changeset(%{order: 6, type: "Missions", course_id: 1}, :invalid)
    end
  end
end
