defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments
  alias Cadet.Assessments.{Assessment, AssessmentType, Question}

  test "create assessments of all types" do
    for type <- AssessmentType.__enum_map__() do
      title_string = Atom.to_string(type)

      {_res, assessment} =
        Assessments.create_assessment(%{
          title: title_string,
          type: type,
          number:
            "#{type |> Atom.to_string() |> String.first() |> String.upcase()}#{Enum.random(0..10)}",
          open_at: Timex.now(),
          close_at: Timex.shift(Timex.now(), days: 7)
        })

      assert %{title: ^title_string, type: ^type} = assessment
    end
  end

  test "create programming question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :programming,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name(),
            prepend: "",
            template: Faker.Lorem.Shakespeare.as_you_like_it(),
            postpend: "",
            solution: Faker.Lorem.Shakespeare.hamlet()
          }
        },
        assessment.id
      )

    assert %{type: :programming} = question
  end

  test "create multiple choice question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :mcq,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name(),
            choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
          }
        },
        assessment.id
      )

    assert %{type: :mcq} = question
  end

  test "create question when there already exists questions" do
    assessment = insert(:assessment)
    _ = insert(:mcq_question, assessment: assessment, display_order: 1)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :mcq,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name(),
            choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
          }
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

  test "update question" do
    question = insert(:question, display_order: 1)
    Assessments.update_question(question.id, %{display_order: 5})
    question = Repo.get(Question, question.id)
    assert question.display_order == 5
  end

  test "delete question" do
    question = insert(:question)
    Assessments.delete_question(question.id)
    assert Repo.get(Question, question.id) == nil
  end
end
