defmodule Cadet.Assessments.SubmissionTest do
  alias Cadet.Assessments.Submission

  use Cadet.DataCase
  use Cadet.Test.ChangesetHelper, entity: Submission

  @required_fields ~w(student_id assessment_id)a

  setup do
    assessment = insert(:assessment)
    student = insert(:user, %{role: :student})

    valid_params = %{student_id: student.id, assessment_id: assessment.id}

    {:ok, %{assessment: assessment, student: student, valid_params: valid_params}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "converts valid params with models into ids", %{assessment: assessment, student: student} do
      assert_changeset_db(%{student: student, assessment: assessment}, :valid)
    end

    test "invalid changeset missing params", %{valid_params: params} do
      for field <- @required_fields do
        params_missing_field = Map.delete(params, field)

        assert_changeset(params_missing_field, :invalid)
      end
    end

    test "invalid changeset foreign key constraint", %{
      assessment: assessment,
      student: student,
      valid_params: params
    } do
      {:ok, _} = Repo.delete(student)

      assert_changeset_db(params, :invalid)

      new_student = insert(:user, %{role: :student})
      {:ok, _} = Repo.delete(assessment)

      assert_changeset_db(Map.put(params, :student_id, new_student.id), :invalid)
    end
  end
end
