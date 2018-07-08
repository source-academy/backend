defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments
  alias Cadet.Assessments.{Assessment, AssessmentType, Question}

  test "all open assessments" do
    open_assessment = insert(:assessment, is_published: true, type: :mission)
    closed_assessment = insert(:assessment, is_published: false, type: :mission)
    result = Enum.map(Assessments.all_open_assessments(:mission), fn m -> m.id end)
    assert open_assessment.id in result
    refute closed_assessment.id in result
  end

  test "create assessments of all types" do
    Enum.each(AssessmentType.__enum_map__(), fn type ->
      title_string = Atom.to_string(type)

      {_res, assessment} =
        Assessments.create_assessment(%{
          title: title_string,
          type: type,
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: 7)
        })

      assert %{title: ^title_string, type: ^type} = assessment
    end)
  end

  test "create programming question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          title: "question",
          type: :programming,
          question: %{},
          raw_question:
            Poison.encode!(%{
              content: "asd",
              solution_template: "template",
              solution: "soln",
              library: %{version: 1}
            })
        },
        assessment.id
      )

    assert %{title: "question", type: :programming} = question
  end

  test "create multiple choice question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          title: "question",
          type: :multiple_choice,
          question: %{},
          raw_question:
            Poison.encode!(%{content: "asd", choices: [%{is_correct: true, content: "asd"}]})
        },
        assessment.id
      )

    assert %{title: "question", type: :multiple_choice} = question
  end

  test "create question when there already exists questions" do
    assessment = insert(:assessment)
    _ = insert(:question, assessment: assessment, display_order: 1)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          title: "question",
          type: :multiple_choice,
          question: %{},
          raw_question:
            Poison.encode!(%{content: "asd", choices: [%{is_correct: true, content: "asd"}]})
        },
        assessment.id
      )

    assert %{display_order: 2} = question
  end

  test "create invalid question" do
    assessment = insert(:assessment)

    assert {:error, _} = Assessments.create_question_for_assessment(%{}, assessment.id)
  end

  test "publish assessment" do
    assessment = insert(:assessment, is_published: false)

    {:ok, assessment} = Assessments.publish_assessment(assessment.id)
    assert assessment.is_published == true
  end

  test "update assessment" do
    assessment = insert(:assessment, title: "assessment")

    Assessments.update_assessment(assessment.id, %{title: "changed_assessment"})

    assessment = Repo.get(Assessment, assessment.id)

    assert assessment.title == "changed_assessment"
  end

  test "all assessments with type" do
    assessment = insert(:assessment, type: :mission)
    sidequest = insert(:assessment, type: :sidequest)
    contest = insert(:assessment, type: :contest)
    path = insert(:assessment, type: :path)
    assert assessment.id in Enum.map(Assessments.all_assessments(:mission), fn m -> m.id end)
    assert sidequest.id in Enum.map(Assessments.all_assessments(:sidequest), fn m -> m.id end)
    assert contest.id in Enum.map(Assessments.all_assessments(:contest), fn m -> m.id end)
    assert path.id in Enum.map(Assessments.all_assessments(:path), fn m -> m.id end)
  end

  test "due assessments" do
    assessment_before_now =
      insert(
        :assessment,
        open_at: Timex.shift(Timex.now(), weeks: -1),
        close_at: Timex.shift(Timex.now(), days: -2),
        is_published: true
      )

    assessment_in_timerange =
      insert(
        :assessment,
        open_at: Timex.shift(Timex.now(), days: -1),
        close_at: Timex.shift(Timex.now(), days: 4),
        is_published: true
      )

    assessment_far =
      insert(
        :assessment,
        open_at: Timex.shift(Timex.now(), days: -2),
        close_at: Timex.shift(Timex.now(), weeks: 2),
        is_published: true
      )

    result = Enum.map(Assessments.assessments_due_soon(), fn m -> m.id end)

    assert assessment_in_timerange.id in result
    refute assessment_before_now.id in result
    refute assessment_far.id in result
  end

  test "update question" do
    question = insert(:question)
    Assessments.update_question(question.id, %{title: "new_title"})
    question = Repo.get(Question, question.id)
    assert question.title == "new_title"
  end

  test "delete question" do
    question = insert(:question)
    Assessments.delete_question(question.id)
    assert Repo.get(Question, question.id) == nil
  end
end
