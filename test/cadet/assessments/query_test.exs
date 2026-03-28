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
      course.id
      |> Query.all_assessments_with_aggregates()
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
      course.id
      |> Query.all_assessments_with_aggregates()
      |> where(id: ^assessment.id)
      |> Repo.one()

    assert result.has_llm_questions == false
  end

  test "course_has_llm_content? returns false when course has no assessments" do
    course = insert(:course)

    assert Query.course_has_llm_content?(course.id) == false
  end

  test "course_has_llm_content? returns true when assessment has non-empty llm_assessment_prompt" do
    course = insert(:course)
    insert(:assessment, course: course, llm_assessment_prompt: "Use this grading rubric")

    assert Query.course_has_llm_content?(course.id) == true
  end

  test "course_has_llm_content? returns true when any question has non-empty llm_prompt" do
    course = insert(:course)
    assessment = insert(:assessment, course: course, llm_assessment_prompt: nil)

    insert(:question,
      assessment: assessment,
      question: build(:programming_question_content, llm_prompt: "Provide AI feedback")
    )

    assert Query.course_has_llm_content?(course.id) == true
  end

  test "course_has_llm_content? returns false when llm_assessment_prompt is empty and question llm_prompt values are nil or empty" do
    course = insert(:course)
    assessment = insert(:assessment, course: course, llm_assessment_prompt: "")

    insert(:question,
      assessment: assessment,
      question: build(:programming_question_content, llm_prompt: nil)
    )

    insert(:question,
      assessment: assessment,
      question: build(:programming_question_content, llm_prompt: "")
    )

    assert Query.course_has_llm_content?(course.id) == false
  end
end
