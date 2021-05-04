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

      # 5 students
      student_list =
        Enum.map(
          1..5,
          fn _index -> insert(:user) end
        )

      # each student has a contest submission
      submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: contest_assessment,
              status: "submitted"
            )
          end
        )

      # each student has an answer
      ans_list =
        Enum.map(
          submission_list,
          fn submission ->
            insert(
              :answer,
              submission: submission,
              question: voting_question
            )
          end
        )

      _submission_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  rank: index + 1,
                  user: student,
                  submission: submission,
                  question: voting_question
                )
              end
            )
          end
        )

      %{answers: ans_list, question_id: voting_question.id, student_list: student_list}
    end

    test "computes correct relative_score with lexing/penalty and fetches highest x relative_score correctly",
         %{answers: _answers, question_id: question_id, student_list: _student_list} do
      Assessments.compute_relative_score(question_id)

      top_x_ans = Assessments.fetch_top_relative_score_answers(question_id, 5)

      assert get_answer_relative_scores(top_x_ans) == [
               99.0,
               89.0,
               79.0,
               69.0,
               59.0
             ]

      x = 3
      top_x_ans = Assessments.fetch_top_relative_score_answers(question_id, x)

      # verify that top x ans are queried correctly
      assert get_answer_relative_scores(top_x_ans) == [99.0, 89.0, 79.0]
    end
  end

  describe "tests leaderboard updating" do
    setup do
      current_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -1),
          close_at: Timex.shift(Timex.now(), days: +1),
          type: "practical"
        )

      current_question = insert_list(1, :voting_question, assessment: current_assessment)

      yesterday_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: "practical"
        )

      yesterday_question = insert_list(1, :voting_question, assessment: yesterday_assessment)

      past_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), days: -4),
          type: "practical"
        )

      _past_question =
        insert(:voting_question,
          assessment: past_assessment
        )

      %{yesterday_question: yesterday_question, current_question: current_question}
    end

    test "fetch_voting_questions_due_yesterday only fetching voting questions closed yesterday",
         %{yesterday_question: yesterday_question, current_question: _current_question} do
      assert get_question_ids(yesterday_question) ==
               get_question_ids(Assessments.fetch_voting_questions_due_yesterday())
    end

    test "fetch_active_voting_questions only fetches active voting questions",
         %{yesterday_question: _yesterday_question, current_question: current_question} do
      assert get_question_ids(current_question) ==
               get_question_ids(Assessments.fetch_active_voting_questions())
    end

    # TODO: finish writing up tests
    # test "update_final_contest_leaderboards correctly updates leaderboards
    # that voting closed yesterday"
    # end

    # test "update_rolling_contest_leaderboards correcly updates leaderboards
    # which voting is active" do
    # end
  end

  defp get_answer_relative_scores(answers) do
    answers |> Enum.map(fn ans -> ans.relative_score end)
  end

  defp get_question_ids(questions) do
    questions |> Enum.map(fn q -> q.id end) |> Enum.sort()
  end
end
