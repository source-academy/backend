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
      contest_question = insert(:programming_question)
      question = insert(:voting_question)
      users = Enum.map(0..5, fn _x -> insert(:user, role: "student") end)

      Enum.map(users, fn user ->
        submission =
          insert(:submission,
            student: user,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      unattempted_student = insert(:user, role: "student")

      # unattempted submission will automatically be submitted after the assessment closes.
      unattempted_submission =
        insert(:submission,
          student: unattempted_student,
          assessment: contest_question.assessment,
          status: "submitted"
        )

      insert(:answer,
        answer: %{
          code: "// question was left blank by student"
        },
        submission: unattempted_submission,
        question: contest_question
      )

      Assessments.insert_voting(contest_question.assessment.number, question.id)

      # students with own contest submissions will vote for 5 entries
      # students without own contest submissin will vote for 6 entries
      assert length(Repo.all(SubmissionVotes, question_id: question.id)) == 6 * 5 + 6
    end

    test "create voting parameters with invalid contest number" do
      question = insert(:voting_question)

      {status, _} = Assessments.insert_voting("", question.id)

      assert status == :error
    end

    test "deletes submission_votes when assessment is deleted" do
      contest_question = insert(:programming_question)
      voting_assessment = insert(:assessment, type: "practical")
      question = insert(:voting_question, assessment: voting_assessment)
      users = Enum.map(0..5, fn _x -> insert(:user, role: "student") end)

      Enum.map(users, fn user ->
        submission =
          insert(:submission,
            student: user,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      Assessments.insert_voting(contest_question.assessment.number, question.id)
      assert Repo.exists?(SubmissionVotes, question_id: question.id)

      Assessments.delete_assessment(voting_assessment.id)
      refute Repo.exists?(SubmissionVotes, question_id: question.id)
    end
  end

  describe "contest voting leaderboard utility functions" do
    setup do
      contest_assessment = insert(:assessment, type: "contest")
      voting_assessment = insert(:assessment, type: "practical")
      voting_question = insert(:voting_question, assessment: voting_assessment)

      # generate 5 students
      student_list =
        Enum.map(
          1..5,
          fn _index -> insert(:user) end
        )

      # generate contest submission for each student
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

      # generate answer for each student
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

      # generate submission votes for each student
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

  describe "contest leaderboard updating functions" do
    setup do
      current_contest_assessment = insert(:assessment, type: "contest")
      # contest_voting assessment that is still ongoing
      current_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -1),
          close_at: Timex.shift(Timex.now(), days: +1),
          type: "practical"
        )

      current_question = insert(:voting_question, assessment: current_assessment)

      yesterday_contest_assessment = insert(:assessment, type: "contest")
      # contest_voting assessment closed yesterday
      yesterday_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: "practical"
        )

      yesterday_question = insert(:voting_question, assessment: yesterday_assessment)

      past_contest_assessment = insert(:assessment, type: "contest")
      # contest voting assessment closed >1 day ago
      past_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), days: -4),
          type: "practical"
        )

      past_question =
        insert(:voting_question,
          assessment: past_assessment
        )

      # generate 5 students
      student_list =
        Enum.map(
          1..5,
          fn _index -> insert(:user) end
        )

      # generate contest submission for each user
      current_submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: current_contest_assessment,
              status: "submitted"
            )
          end
        )

      yesterday_submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: yesterday_contest_assessment,
              status: "submitted"
            )
          end
        )

      past_submission_list =
        Enum.map(
          student_list,
          fn student ->
            insert(
              :submission,
              student: student,
              assessment: past_contest_assessment,
              status: "submitted"
            )
          end
        )

      # generate answers for each submission for each student
      Enum.map(
        current_submission_list,
        fn submission ->
          insert(
            :answer,
            submission: submission,
            question: current_question
          )
        end
      )

      Enum.map(
        yesterday_submission_list,
        fn submission ->
          insert(
            :answer,
            submission: submission,
            question: yesterday_question
          )
        end
      )

      Enum.map(
        past_submission_list,
        fn submission ->
          insert(
            :answer,
            submission: submission,
            question: past_question
          )
        end
      )

      # generate votes by each user for each contest entry
      _current_assessment_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(current_submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  rank: index + 1,
                  user: student,
                  submission: submission,
                  question: current_question
                )
              end
            )
          end
        )

      _yesterday_assessment_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(yesterday_submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  rank: index + 1,
                  user: student,
                  submission: submission,
                  question: yesterday_question
                )
              end
            )
          end
        )

      _past_assessment_votes =
        Enum.map(
          student_list,
          fn student ->
            Enum.map(
              Enum.with_index(past_submission_list),
              fn {submission, index} ->
                insert(
                  :submission_vote,
                  rank: index + 1,
                  user: student,
                  submission: submission,
                  question: past_question
                )
              end
            )
          end
        )

      %{
        yesterday_question: yesterday_question,
        current_question: current_question,
        past_question: past_question
      }
    end

    test "fetch_voting_questions_due_yesterday only fetching voting questions closed yesterday",
         %{
           yesterday_question: yesterday_question,
           current_question: _current_question,
           past_question: _past_question
         } do
      assert get_question_ids([yesterday_question]) ==
               get_question_ids(Assessments.fetch_voting_questions_due_yesterday())
    end

    test "fetch_active_voting_questions only fetches active voting questions",
         %{
           yesterday_question: _yesterday_question,
           current_question: current_question,
           past_question: _past_question
         } do
      assert get_question_ids([current_question]) ==
               get_question_ids(Assessments.fetch_active_voting_questions())
    end

    test "update_final_contest_leaderboards correctly updates leaderboards
    that voting closed yesterday",
         %{
           yesterday_question: yesterday_question,
           current_question: current_question,
           past_question: past_question
         } do
      Assessments.update_final_contest_leaderboards()

      # does not update scores for voting assessments closed  >1 days and those ongoing ago
      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(past_question.id, 1)
             ) == [0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(current_question.id, 1)
             ) == [0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(yesterday_question.id, 5)
             ) == [99.0, 89.0, 79.0, 69.0, 59.0]
    end

    test "update_rolling_contest_leaderboards correcly updates leaderboards
      which voting is active",
         %{
           yesterday_question: yesterday_question,
           current_question: current_question,
           past_question: past_question
         } do
      Assessments.update_rolling_contest_leaderboards()

      # does not update scores for voting assessments closed >1 days ago
      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(past_question.id, 1)
             ) == [0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(yesterday_question.id, 1)
             ) == [0]

      assert get_answer_relative_scores(
               Assessments.fetch_top_relative_score_answers(current_question.id, 5)
             ) == [99.0, 89.0, 79.0, 69.0, 59.0]
    end
  end

  defp get_answer_relative_scores(answers) do
    answers |> Enum.map(fn ans -> ans.relative_score end)
  end

  defp get_question_ids(questions) do
    questions |> Enum.map(fn q -> q.id end) |> Enum.sort()
  end
end
