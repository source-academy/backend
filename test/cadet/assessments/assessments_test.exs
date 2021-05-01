defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  alias Cadet.Assessments
  alias Cadet.Assessments.{Assessment, Question, SubmissionVotes}

  test "create assessments of all types" do
    for type <- Assessment.assessment_types() do
      title_string = type

      {_res, assessment} =
        Assessments.create_assessment(%{
          title: title_string,
          type: type,
          number: "#{type |> String.upcase()}#{Enum.random(0..10)}",
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

  test "create voting question" do
    assessment = insert(:assessment)

    {:ok, question} =
      Assessments.create_question_for_assessment(
        %{
          type: :voting,
          library: build(:library),
          question: %{
            content: Faker.Pokemon.name()
          }
        },
        assessment.id
      )

    assert %{type: :voting} = question
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

  describe "contest voting" do
    test "inserts votes into submission_votes table" do
      assessment = insert(:assessment, type: "contest")
      question = insert(:voting_question)
      users = Enum.map(0..5, fn _x -> insert(:user) end)

      Enum.map(users, fn user ->
        insert(:submission, student: user, assessment: assessment, status: "submitted")
      end)

      usernames = Enum.map(users, fn user -> %{username: user.username} end)

      Assessments.insert_voting(assessment.number, usernames, question.id)
      assert length(Repo.all(SubmissionVotes, question_id: question.id)) == 30
    end

    test "create voting parameters with invalid contest number" do
      question = insert(:voting_question)

      {status, _} = Assessments.insert_voting("", [], question.id)

      assert status == :error
    end

    test "deletes submission_votes when assessment is deleted" do
      contest_assessment = insert(:assessment, type: "contest")
      voting_assessment = insert(:assessment, type: "practical")
      question = insert(:voting_question, assessment: voting_assessment)
      users = Enum.map(0..5, fn _x -> insert(:user) end)

      Enum.map(users, fn user ->
        insert(:submission, student: user, assessment: contest_assessment, status: "submitted")
      end)

      usernames = Enum.map(users, fn user -> %{username: user.username} end)

      Assessments.insert_voting(contest_assessment.number, usernames, question.id)

      admin = insert(:user, role: "admin")
      Assessments.delete_assessment(admin, voting_assessment.id)
      refute Repo.exists?(SubmissionVotes, question_id: question.id)
    end
  end

  describe "contest voting leaderboard" do
    setup do
      contest_assessment = insert(:assessment, type: "contest")
      voting_assessment = insert(:assessment, type: "practical")
      voting_question = insert(:voting_question, assessment: voting_assessment)

      # mock vote score data
      vote_scores = [25.00, 30.50, 40.50, 50.99, 51.00, 70.10, 70.20, 80.91, 80.99, 91.3, 99.99]

      ans_list =
        Enum.map(
          vote_scores,
          fn vote_score ->
            student = insert(:user)

            submission =
              insert(:submission,
                student: student,
                assessment: contest_assessment,
                status: "submitted"
              )

            insert(:answer,
              submission: submission,
              question: voting_question,
              grade: round(vote_score * 1_000_000)
            )
          end
        )

      %{answers: ans_list, question_id: voting_question.id}
    end

    test "fetches entries with highest grade", %{answers: _answers, question_id: question_id} do
      x = 3
      top_x_ans = Assessments.fetch_top_grade_answers(question_id, x)

      # verify that top x ans are queried correctly
      assert Enum.map(top_x_ans, fn ans -> ans.score end) == [99_990_000, 91_300_000, 80_990_000]
    end
  end
end
