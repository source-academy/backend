defmodule Cadet.Assessments.SubmissionTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Submission

  @required_fields ~w(student_id assessment_id)a

  setup do
    assessment = insert(:assessment)
    student = insert(:user, %{role: :student})

    valid_params = %{student_id: student.id, assessment_id: assessment.id}

    {:ok, %{assessment: assessment, student: student, valid_params: valid_params}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      result =
        %Submission{}
        |> Submission.changeset(params)
        |> Repo.insert()

      assert({:ok, _} = result, inspect(result))
    end

    test "converts valid params with models into ids", %{assessment: assessment, student: student} do
      result =
        %Submission{}
        |> Submission.changeset(%{student: student, assessment: assessment})
        |> Repo.insert()

      assert({:ok, _} = result, inspect(result))
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

      result =
        %Submission{}
        |> Submission.changeset(params)
        |> Repo.insert()

      assert({:error, _} = result, inspect(result))

      new_student = insert(:user, %{role: :student})
      {:ok, _} = Repo.delete(assessment)

      result =
        %Submission{}
        |> Submission.changeset(Map.put(params, :student_id, new_student.id))
        |> Repo.insert()

      assert({:error, _} = result, inspect(result))
    end
  end
end
