defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments
  alias Cadet.Accounts

  test "all assessments" do
    assessments = [
      insert(:assessment),
      insert(:assessment),
      insert(:assessment),
      insert(:assessment),
      insert(:assessment)
    ]

    result = Assessments.all_assessments()
    assert Enum.all?(result, fn x -> x.id in Enum.map(assessments, fn m -> m.id end) end)
  end

  test "all open assessments" do
    open_assessment = insert(:assessment, is_published: true, category: :mission)
    closed_assessment = insert(:assessment, is_published: false, category: :mission)
    result = Enum.map(Assessments.all_open_assessments(:mission), fn m -> m.id end)
    assert open_assessment.id in result
    refute closed_assessment.id in result
  end

  test "create assessment" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "assessment",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert assessment.title == "assessment"
    assert assessment.category == :mission
  end

  test "create sidequest" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "sidequest",
        category: :sidequest,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert assessment.title == "sidequest"
    assert assessment.category == :sidequest
  end

  test "create contest" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "contest",
        category: :contest,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert assessment.title == "contest"
    assert assessment.category == :contest
  end

  test "create path" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "path",
        category: :path,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert assessment.title == "path"
    assert assessment.category == :path
  end

  test "create programming question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          type: :programming,
          question: %{},
          raw_question: "{\"content\": \"asd\", \"solution_template\": \"template\",
            \"solution\": \"soln\", \"library\": {\"version\": 1}}"
        },
        assessment.id
      )

    assert question.title == "question"
    assert question.weight == 5
    assert question.type == :programming
  end

  test "create multiple choice question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question(
        %{
          title: "question",
          weight: 5,
          type: :multiple_choice,
          question: %{},
          raw_question:
            "{\"content\":\"asd\",\"choices\":[{\"is_correct\":true,\"content\":\"asd\"}]}"
        },
        assessment.id
      )

    assert question.title == "question"
    assert question.weight == 5
    assert question.type == :multiple_choice
  end

  test "publish assessment" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "assessment",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    {:ok, assessment} = Assessments.publish_assessment(assessment.id)
    assert assessment.is_published == true
  end

  test "update assessment" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "assessment",
        category: :mission,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    Assessments.update_assessment(assessment.id, %{title: "changed_assessment"})
    assessment = Assessments.get_assessment(assessment.id)
    assert assessment.title == "changed_assessment"
  end

  test "all assessments with category" do
    assessment = insert(:assessment, category: :mission)
    sidequest = insert(:assessment, category: :sidequest)
    contest = insert(:assessment, category: :contest)
    path = insert(:assessment, category: :path)
    assert assessment.id in Enum.map(Assessments.all_assessments(:mission), fn m -> m.id end)
    assert sidequest.id in Enum.map(Assessments.all_assessments(:sidequest), fn m -> m.id end)
    assert contest.id in Enum.map(Assessments.all_assessments(:contest), fn m -> m.id end)
    assert path.id in Enum.map(Assessments.all_assessments(:path), fn m -> m.id end)
  end

  test "due assessments" do
    assessment_before_now = insert(:assessment, close_at: Timex.now(), is_published: true)

    assessment_in_timerange =
      insert(:assessment, close_at: Timex.shift(Timex.now(), days: 4), is_published: true)

    assessment_far =
      insert(
        :assessment,
        close_at: Timex.shift(Timex.now(), weeks: 2),
        is_published: true
      )

    result = Enum.map(Assessments.assessments_due_soon(), fn m -> m.id end)
    assert assessment_in_timerange.id in result
    refute assessment_far.id in result
  end

  test "update question" do
    assessment = insert(:assessment)
    question = insert(:question)
    Assessments.update_question(question.id, %{weight: 10})
    question = Assessments.get_question(question.id)
    assert question.weight == 10
  end

  test "delete question" do
    assessment = insert(:assessment)
    question = insert(:question)
    Assessments.delete_question(question.id)
    assert Assessments.get_question(question.id) == nil
  end

  # test "assessment and its questions" do
  #  assessment1 = insert(:assessment)
  #  assessment2 = insert(:assessment)
  #  question1 = insert(:question) 
  #  question2 = insert(:question)
  #  assert assessment1 in Assessments.get_assessment_and_questions(assessment1.id)
  # end
end
