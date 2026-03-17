defmodule Cadet.Assessments.QueryTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Query

  test "all_assessments_with_max_grade" do
    assessment = insert(:assessment)
    insert_list(5, :question, assessment: assessment, max_xp: 200)

    result =
      Query.all_assessments_with_max_xp()
      |> where(id: ^assessment.id)
      |> Repo.one()

    assessment_id = assessment.id

    assert %{max_xp: 1000, id: ^assessment_id} = result
  end

  test "assessments_max_grade" do
    assessment = insert(:assessment)
    insert_list(5, :question, assessment: assessment, max_xp: 200)

    result =
      Query.assessments_max_xp()
      |> Repo.all()
      |> Enum.find(&(&1.assessment_id == assessment.id))

    assert result.max_xp == 1000
  end

  test "all_assessments_with_aggregates sets has_llm_questions to true when any question has non-empty llm_prompt" do
    course = insert(:course)
    assessment = insert(:assessment, course: course)

    insert(:question,
      assessment: assessment,
      question: build(:programming_question_content, llm_prompt: "Provide AI feedback")
    )

    insert(:question,
      assessment: assessment,
      question: build(:programming_question_content, llm_prompt: nil)
    )

    result =
      Query.all_assessments_with_aggregates(course.id)
      |> where(id: ^assessment.id)
      |> Repo.one()

    assert result.has_llm_questions == true
  end

  test "all_assessments_with_aggregates sets has_llm_questions to false when all llm_prompt values are nil or empty" do
    course = insert(:course)
    assessment = insert(:assessment, course: course)

    insert(:question,
      assessment: assessment,
      question: build(:programming_question_content, llm_prompt: nil)
    )

    insert(:question,
      assessment: assessment,
      question: build(:programming_question_content, llm_prompt: "")
    )

    result =
      Query.all_assessments_with_aggregates(course.id)
      |> where(id: ^assessment.id)
      |> Repo.one()

    assert result.has_llm_questions == false
  end
end
