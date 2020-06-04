defmodule Cadet.Assessments.QueryTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Query

  test "all_assessments_with_max_grade" do
    assessment = insert(:assessment)
    insert_list(5, :question, assessment: assessment, max_grade: 200)

    result =
      Query.all_assessments_with_max_grade()
      |> where(id: ^assessment.id)
      |> Repo.one()

    assessment_id = assessment.id

    assert %{max_grade: 1000, id: ^assessment_id} = result
  end

  test "assessments_max_grade" do
    assessment = insert(:assessment)
    insert_list(5, :question, assessment: assessment, max_grade: 200)

    result =
      Query.assessments_max_grade()
      |> Repo.all()
      |> Enum.find(&(&1.assessment_id == assessment.id))

    assert result.max_grade == 1000
  end
end
