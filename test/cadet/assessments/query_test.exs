defmodule Cadet.Assessments.QueryTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Query

  test "all_submissions_with_grade/1" do
    submission = insert(:submission)
    assessment = insert(:assessment)
    questions = insert_list(5, :question, assessment: assessment)

    Enum.each(questions, &insert(:answer, submission: submission, grade: 200, question: &1))

    result =
      Query.all_submissions_with_grade()
      |> where(id: ^submission.id)
      |> Repo.one()

    submission_id = submission.id

    assert %{grade: 1000, id: ^submission_id} = result
  end

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

  test "submissions_grade" do
    submission = insert(:submission)
    assessment = insert(:assessment)
    questions = insert_list(5, :question, assessment: assessment)

    Enum.each(
      questions,
      &insert(:answer, submission: submission, grade: 200, adjustment: -100, question: &1)
    )

    result =
      Query.submissions_grade()
      |> Repo.all()
      |> Enum.find(&(&1.submission_id == submission.id))

    assert result.grade == 500
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
