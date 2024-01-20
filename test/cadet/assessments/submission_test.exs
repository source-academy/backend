defmodule Cadet.Assessments.SubmissionTest do
  alias Cadet.Assessments.Submission

  use Cadet.ChangesetCase, entity: Submission

  @required_fields ~w(assessment_id)a

  setup do
    course = insert(:course)
    config = insert(:assessment_config, %{course: course})
    assessment = insert(:assessment, %{config: config, course: course})
    team_assessment = insert(:assessment, %{config: config, course: course})
    student = insert(:course_registration, %{course: course, role: :student})
    student1 = insert(:course_registration, %{course: course, role: :student})
    student2 = insert(:course_registration, %{course: course, role: :student})

    teammember1 = insert(:team_member, %{student: student1})
    teammember2 = insert(:team_member, %{student: student2})
    team = insert(:team, %{assessment: team_assessment, team_members: [teammember1, teammember2]})

    valid_params = %{student_id: student.id, assessment_id: assessment.id}
    valid_params_with_team = %{student_id: nil, team_id: team.id, assessment_id: assessment.id}
    invalid_params_without_both = %{student_id: nil, team_id: nil, assessment_id: assessment.id}

    invalid_params_with_both = %{
      student_id: student1.id,
      team_id: team.id,
      assessment_id: assessment.id
    }

    {:ok,
     %{
       assessment: assessment,
       student: student,
       team: team,
       valid_params: valid_params,
       valid_params_with_team: valid_params_with_team,
       invalid_params_without_both: invalid_params_without_both,
       invalid_params_with_both: invalid_params_with_both
     }}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      params
      |> assert_changeset_db(:valid)
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

    test "valid changeset with only team", %{
      valid_params_with_team: params
    } do
      assert_changeset_db(params, :valid)
    end

    test "invalid changeset without team and student", %{
      invalid_params_without_both: params
    } do
      assert_changeset_db(params, :invalid)
    end

    test "invalid changeset with both team and student", %{
      invalid_params_with_both: params
    } do
      assert_changeset_db(params, :invalid)
    end
  end
end
