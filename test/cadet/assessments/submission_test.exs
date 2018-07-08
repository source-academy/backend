defmodule Cadet.Assessments.SubmissionTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Submission

  @required_fields ~w(student_id assessment_id)a

  setup do
    assessment = insert(:assessment)
    student = insert(:user, %{role: :student})

    valid_params = %{student_id: student.id, assessment_id: assessment.id}

    {:ok, [assessment: assessment, student: student, valid_params: valid_params]}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      {res, _struct} =
        %Submission{}
        |> Submission.changeset(params)
        |> Repo.insert()

      assert res == :ok
    end

    test "converts valid params with models into ids", %{assessment: assessment, student: student} do
      {res, _struct} =
        %Submission{}
        |> Submission.changeset(%{student: student, assessment: assessment})
        |> Repo.insert()

      assert res == :ok
    end

    test "invalid changeset missing params", %{valid_params: params} do
      Enum.each(@required_fields, fn field ->
        params_missing_field = Map.delete(params, field)

        refute(
          Submission.changeset(%Submission{}, params_missing_field).valid?,
          inspect(params_missing_field)
        )
      end)
    end

    test "invalid changeset foreign key constraint", %{
      assessment: assessment,
      student: student,
      valid_params: params
    } do
      {:ok, _} = Repo.delete(student)

      {_res, changeset} =
        %Submission{}
        |> Submission.changeset(params)
        |> Repo.insert()

      refute(changeset.valid?, inspect(changeset))

      new_student = insert(:user, %{role: :student})
      {:ok, _} = Repo.delete(assessment)

      {_res, changeset} =
        %Submission{}
        |> Submission.changeset(Map.put(params, :student_id, new_student.id))
        |> Repo.insert()

      refute(changeset.valid?, inspect(changeset))
    end
  end
end
