defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments
  alias Cadet.Accounts

  test "all assessments" do
    assessments = Enum.map(insert_list(5, :assessment), & &1.id)

    result = Enum.map(Assessments.all_assessments(), & &1.id)
    assert result == assessments
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

    assert %{title: "assessment", category: :mission} = assessment
  end

  test "create sidequest" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "sidequest",
        category: :sidequest,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert %{title: "sidequest", category: :sidequest} = assessment
  end

  test "create contest" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "contest",
        category: :contest,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert %{title: "contest", category: :contest} = assessment
  end

  test "create path" do
    {:ok, assessment} =
      Assessments.create_assessment(%{
        title: "path",
        category: :path,
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert %{title: "path", category: :path} = assessment
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

    assert %{title: "question", weight: 5, type: :programming} = question
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
            Poison.encode!(%{content: "asd", choices: [%{is_correct: true, content: "asd"}]})
        },
        assessment.id
      )

    assert %{title: "question", weight: 5, type: :multiple_choice}
  end

  test "publish assessment" do
    assessment = insert(:assessment, is_published: false)

    {:ok, assessment} = Assessments.publish_assessment(assessment.id)
    assert assessment.is_published == true
  end

  test "update assessment" do
    assessment = insert(:assessment, title: "assessment")

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
    Assessments.update_question(question.id, %{weight: 10})
    question = Assessments.get_question(question.id)
    assert question.weight == 10
  end

  test "delete question" do
    question = insert(:question)
    Assessments.delete_question(question.id)
    assert Assessments.get_question(question.id) == nil
  end
end
