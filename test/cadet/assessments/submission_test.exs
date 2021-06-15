defmodule Cadet.Assessments.SubmissionTest do
  alias Cadet.Assessments.Submission

  use Cadet.ChangesetCase, entity: Submission

  @required_fields ~w(student_id assessment_id)a

  setup do
    course = insert(:course)
    type = insert(:assessment_type, %{course: course})
    assessment = insert(:assessment, %{type: type, course: course})
    student = insert(:course_registration, %{course: course, role: :student})

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

      new_student = insert(:course_registration, %{role: :student})
      {:ok, _} = Repo.delete(assessment)

      params
      |> Map.put(:student_id, new_student.id)
      |> assert_changeset_db(:invalid)
    end
  end
end
