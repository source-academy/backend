defmodule Cadet.AssessmentsTest do
  use Cadet.DataCase

  import Cadet.{Factory, TestEntityHelper}

  alias Cadet.Assessments
  alias Cadet.Assessments.{Assessment, Question, SubmissionVotes}

  test "create assessments of all types" do
    course = insert(:course)
    config = insert(:assessment_config, %{type: "Test", course: course})
    course_id = course.id
    config_id = config.id

    {_res, assessment} =
      Assessments.create_assessment(%{
        course_id: course_id,
        title: "test",
        config_id: config_id,
        number: "#{config.type |> String.upcase()}#{Enum.random(0..10)}",
        open_at: Timex.now(),
        close_at: Timex.shift(Timex.now(), days: 7)
      })

    assert %{title: "test", config_id: ^config_id, course_id: ^course_id} = assessment
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
            content: Faker.Pokemon.name(),
            contest_number: assessment.number,
            reveal_hours: 48,
            token_divider: 50
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
    course = insert(:course)
    config = insert(:assessment_config, %{course: course})
    assessment = insert(:assessment, %{is_published: false, course: course, config: config})

    {:ok, assessment} = Assessments.publish_assessment(assessment.id)
    assert assessment.is_published == true
  end

  test "update assessment" do
    course = insert(:course)
    config = insert(:assessment_config, %{course: course})
    assessment = insert(:assessment, %{title: "assessment", course: course, config: config})

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
    test "inserts votes into submission_votes table if contest has closed" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that has closed
      closed_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      contest_question = insert(:programming_question, assessment: closed_contest_assessment)
      voting_assessment = insert(:assessment, %{course: course})

      question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question:
            build(:voting_question_content, contest_number: closed_contest_assessment.number)
        })

      students =
        insert_list(6, :course_registration, %{
          role: :student,
          course: course
        })

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      unattempted_student = insert(:course_registration, %{role: :student, course: course})

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

      Assessments.insert_voting(course.id, contest_question.assessment.number, question.id)

      # students with own contest submissions will vote for 5 entries
      # students without own contest submissin will vote for 6 entries
      assert SubmissionVotes |> where(question_id: ^question.id) |> Repo.all() |> length() ==
               6 * 5 + 6
    end

    test "does not insert entries for voting if contest is still open" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that is still open
      open_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: 1),
          course: course,
          config: config
        )

      contest_question = insert(:programming_question, assessment: open_contest_assessment)
      voting_assessment = insert(:assessment, %{course: course})

      question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question:
            build(:voting_question_content, contest_number: open_contest_assessment.number)
        })

      students =
        insert_list(6, :course_registration, %{
          role: :student,
          course: course
        })

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      Assessments.insert_voting(course.id, contest_question.assessment.number, question.id)

      # No entries should be released for students to vote on while the contest is still open
      assert SubmissionVotes |> where(question_id: ^question.id) |> Repo.all() |> length() == 0
    end

    test "function that checks for closed contests and releases entries into voting pool" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that has closed
      closed_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      # contest assessment that is still open
      open_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: 1),
          course: course,
          config: config
        )

      # contest assessment that is closed but insert_voting has already been done
      compiled_contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      closed_contest_question =
        insert(:programming_question, assessment: closed_contest_assessment)

      open_contest_question = insert(:programming_question, assessment: open_contest_assessment)

      compiled_contest_question =
        insert(:programming_question, assessment: compiled_contest_assessment)

      closed_voting_assessment = insert(:assessment, %{course: course})
      open_voting_assessment = insert(:assessment, %{course: course})
      compiled_voting_assessment = insert(:assessment, %{course: course})
      # voting assessment that references an invalid contest number
      invalid_voting_assessment = insert(:assessment, %{course: course})

      closed_question =
        insert(:voting_question, %{
          assessment: closed_voting_assessment,
          question:
            build(:voting_question_content, contest_number: closed_contest_assessment.number)
        })

      open_question =
        insert(:voting_question, %{
          assessment: open_voting_assessment,
          question:
            build(:voting_question_content, contest_number: open_contest_assessment.number)
        })

      compiled_question =
        insert(:voting_question, %{
          assessment: compiled_voting_assessment,
          question:
            build(:voting_question_content, contest_number: compiled_contest_assessment.number)
        })

      invalid_question =
        insert(:voting_question, %{
          assessment: invalid_voting_assessment,
          question: build(:voting_question_content, contest_number: "test_invalid")
        })

      students =
        insert_list(10, :course_registration, %{
          role: :student,
          course: course
        })

      first_four = Enum.slice(students, 0..3)
      last_six = Enum.slice(students, 4..9)

      Enum.map(first_four, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: compiled_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: compiled_contest_question
        )
      end)

      # Only the compiled_assessment has already released entries into voting pool
      Assessments.insert_voting(
        course.id,
        compiled_contest_question.assessment.number,
        compiled_question.id
      )

      assert SubmissionVotes |> where(question_id: ^closed_question.id) |> Repo.all() |> length() ==
               0

      assert SubmissionVotes |> where(question_id: ^open_question.id) |> Repo.all() |> length() ==
               0

      assert SubmissionVotes
             |> where(question_id: ^compiled_question.id)
             |> Repo.all()
             |> length() == 4 * 3 + 6 * 4

      assert SubmissionVotes |> where(question_id: ^invalid_question.id) |> Repo.all() |> length() ==
               0

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: closed_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: closed_contest_question
        )
      end)

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: open_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: open_contest_question
        )
      end)

      Enum.map(last_six, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: compiled_contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: compiled_contest_question
        )
      end)

      # fetching all unassigned voting questions should only yield open and closed questions
      unassigned_voting_questions = Assessments.fetch_unassigned_voting_questions()
      assert Enum.count(unassigned_voting_questions) == 2

      unassigned_voting_question_ids =
        Enum.map(unassigned_voting_questions, fn q -> q.question_id end)

      assert closed_question.id in unassigned_voting_question_ids
      assert open_question.id in unassigned_voting_question_ids

      Assessments.update_final_contest_entries()

      # only the closed_contest should have been updated
      assert SubmissionVotes |> where(question_id: ^closed_question.id) |> Repo.all() |> length() ==
               10 * 9

      assert SubmissionVotes |> where(question_id: ^open_question.id) |> Repo.all() |> length() ==
               0

      assert SubmissionVotes
             |> where(question_id: ^compiled_question.id)
             |> Repo.all()
             |> length() == 4 * 3 + 6 * 4

      assert SubmissionVotes |> where(question_id: ^invalid_question.id) |> Repo.all() |> length() ==
               0
    end

    test "create voting parameters with invalid contest number" do
      contest_question = insert(:programming_question)
      question = insert(:voting_question)

      {status, _} =
        Assessments.insert_voting(
          insert(:course).id,
          contest_question.assessment.number,
          question.id
        )

      assert status == :error

      {status, _} =
        Assessments.insert_voting(contest_question.assessment.course_id, "", question.id)

      assert status == :error
    end

    test "deletes submission_votes when assessment is deleted" do
      course = insert(:course)
      config = insert(:assessment_config)
      # contest assessment that has closed
      contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config
        )

      contest_question = insert(:programming_question, assessment: contest_assessment)
      voting_assessment = insert(:assessment, %{course: course, config: config})
      question = insert(:voting_question, assessment: voting_assessment)
      students = insert_list(5, :course_registration, %{role: :student, course: course})

      Enum.map(students, fn student ->
        submission =
          insert(:submission,
            student: student,
            assessment: contest_question.assessment,
            status: "submitted"
          )

        insert(:answer,
          answer: %{code: "return 2;"},
          submission: submission,
          question: contest_question
        )
      end)

      Assessments.insert_voting(course.id, contest_question.assessment.number, question.id)
      assert Repo.exists?(SubmissionVotes, question_id: question.id)

      Assessments.delete_assessment(voting_assessment.id)
      refute Repo.exists?(SubmissionVotes, question_id: question.id)
    end

    test "does not delete contest assessment if referencing voting assessment is present" do
      course = insert(:course)
      config = insert(:assessment_config)

      contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course,
          config: config,
          number: "test"
        )

      voting_assessment = insert(:assessment, %{course: course, config: config})

      # insert voting question that references the contest assessment
      _voting_question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question: build(:voting_question_content, contest_number: contest_assessment.number)
        })

      error_message = {:bad_request, "Contest voting for this contest is still up"}

      assert {:error, ^error_message} = Assessments.delete_assessment(contest_assessment.id)
      # deletion should fail
      assert Assessment |> where(id: ^contest_assessment.id) |> Repo.exists?()
    end

    test "deletes contest assessment if voting assessment references same number but different course" do
      course_1 = insert(:course)
      course_2 = insert(:course)
      config = insert(:assessment_config)

      contest_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -1),
          course: course_1,
          config: config,
          number: "test"
        )

      voting_assessment = insert(:assessment, %{course: course_2, config: config})

      # insert voting question from a different course that references the same contest number
      _voting_question =
        insert(:voting_question, %{
          assessment: voting_assessment,
          question: build(:voting_question_content, contest_number: contest_assessment.number)
        })

      assert {:ok, _} = Assessments.delete_assessment(contest_assessment.id)
      # deletion should succeed
      refute Assessment |> where(id: ^contest_assessment.id) |> Repo.exists?()
    end
  end

  describe "contest voting leaderboard utility functions" do
    setup do
      course = insert(:course)
      config = insert(:assessment_config)
      contest_assessment = insert(:assessment, %{course: course, config: config})
      voting_assessment = insert(:assessment, %{course: course, config: config})
      voting_question = insert(:voting_question, assessment: voting_assessment)

      # generate 5 students
      student_list = insert_list(5, :course_registration, %{course: course, role: :student})

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
              answer: build(:programming_answer),
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
                  score: 10 - index,
                  voter: student,
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

      assert get_answer_relative_scores(top_x_ans) == expected_top_relative_scores(5, 50)

      x = 3
      top_x_ans = Assessments.fetch_top_relative_score_answers(question_id, x)

      # verify that top x ans are queried correctly
      assert get_answer_relative_scores(top_x_ans) == expected_top_relative_scores(3, 50)
    end
  end

  describe "contest leaderboard updating functions" do
    setup do
      course = insert(:course)
      config = insert(:assessment_config)
      current_contest_assessment = insert(:assessment, %{course: course, config: config})
      # contest_voting assessment that is still ongoing
      current_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -1),
          close_at: Timex.shift(Timex.now(), days: +1),
          course: course,
          config: config
        )

      current_question = insert(:voting_question, assessment: current_assessment)

      yesterday_contest_assessment = insert(:assessment, %{course: course, config: config})
      # contest_voting assessment closed yesterday
      yesterday_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          course: course,
          config: config
        )

      yesterday_question = insert(:voting_question, assessment: yesterday_assessment)

      past_contest_assessment = insert(:assessment, %{course: course, config: config})
      # contest voting assessment closed >1 day ago
      past_assessment =
        insert(:assessment,
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), days: -4),
          course: course,
          config: config
        )

      past_question =
        insert(:voting_question,
          assessment: past_assessment
        )

      # generate 5 students
      student_list = insert_list(5, :course_registration, %{course: course, role: :student})

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
            answer: build(:programming_answer),
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
            answer: build(:programming_answer),
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
            answer: build(:programming_answer),
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
                  score: 10 - index,
                  voter: student,
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
                  score: 10 - index,
                  voter: student,
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
                  score: 10 - index,
                  voter: student,
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

    test "update_final_contest_leaderboards correctly updates leaderboards that voting closed yesterday",
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
             ) == expected_top_relative_scores(5, 50)
    end

    test "update_rolling_contest_leaderboards correcly updates leaderboards which voting is active",
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
             ) == expected_top_relative_scores(5, 50)
    end
  end

  describe "get combined xp function" do
    setup do
      course_registration = insert(:course_registration)
      course_id = course_registration.course_id
      user_id = course_registration.user_id
      course_reg_id = course_registration.id

      %{
        test_cr: course_registration,
        course_id: course_id,
        user_id: user_id,
        course_reg_id: course_reg_id
      }
    end

    test "achievement, one completed goal", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 210
    end

    test "achievement, one incomplete goal", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement, one completed and one incomplete goal",
         %{
           test_cr: test_cr,
           course_id: course_id,
           user_id: user_id,
           course_reg_id: course_reg_id
         } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal_complete =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      goal_incomplete =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal_complete.uuid},
          %{goal_uuid: goal_incomplete.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement, goal (no progress entry)", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "no assessments", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: false,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 100
    end

    test "no achievements", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), no goals.", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: []
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one incomplete goal (no progress entry).", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one incomplete goal (with progress entry).", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one goal completed.", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 111
    end

    test "achievement (is_variable_xp: true), with one goal completed and one goal incomplete", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 1,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      goal2 =
        insert(
          :goal,
          Map.merge(
            goal_literal(1),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid},
          %{goal_uuid: goal2.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end

    test "achievement (is_variable_xp: true), one goal with 0 target_count and 0 count", %{
      test_cr: test_cr,
      course_id: course_id,
      user_id: user_id,
      course_reg_id: course_reg_id
    } do
      course = test_cr.course

      assessment = insert(:assessment, %{is_published: true, course: course})
      question = insert(:question, %{assessment: assessment})

      submission =
        insert(:submission, %{
          assessment: assessment,
          student: test_cr,
          status: :submitted,
          xp_bonus: 100
        })

      insert(:answer, %{
        question: question,
        submission: submission,
        xp: 20,
        xp_adjustment: -10
      })

      goal =
        insert(
          :goal,
          Map.merge(
            goal_literal(0),
            %{
              course: course,
              progress: [
                %{
                  count: 0,
                  completed: true,
                  course_reg_id: test_cr.id
                }
              ]
            }
          )
        )

      insert(:achievement, %{
        course: course,
        title: "Rune Master",
        is_task: true,
        is_variable_xp: true,
        position: 1,
        xp: 100,
        card_tile_url:
          "https://source-academy-assets.s3-ap-southeast-1.amazonaws.com/achievement/card-tile/rune-master-tile.png",
        goals: [
          %{goal_uuid: goal.uuid}
        ]
      })

      resp =
        Assessments.user_total_xp(
          course_id,
          user_id,
          course_reg_id
        )

      assert resp == 110
    end
  end

  """
  mix test ./test/cadet/assessments/assessments_test.exs
  TODO:
  assessment: title(D)
  submission:  status(D), notFullyGraded (D)
  course_reg: group, groupName
  user: name, username
  assessment_config: type, isManuallyGraded
  """
  describe "get submission function" do
    setup do
      Cadet.Test.Seeds.assessments()

    end

    test "filter by assessment title", %{course_regs: %{avenger1_cr: avenger}, assessments: assessments} do

      assessment = assessments["mission"][:assessment]
      title = assessment.title
      {_, res} = Assessments.submissions_by_grader_for_index(avenger, %{"title" => title})
      assessments_from_res = res[:data][:assessments]
      Enum.each(assessments_from_res, fn a ->
        assert a.title == title
      end)
    end

    test "filer by submission status", %{course_regs: %{avenger1_cr: avenger}, assessments: assessments} do
      submission = Enum.random(assessments["mission"][:submissions])
      submission_status = submission.status
      {_, res} = Assessments.submissions_by_grader_for_index(avenger, %{"status" => submission_status})
      submissions_from_res = res[:data][:submissions]
      Enum.each(submissions_from_res, fn s ->
        assert s.status == submission_status
      end)
    end

    test "filter by submission grading status", %{course_regs: %{avenger1_cr: avenger}, assessments: assessments} do
      {_, res} = Assessments.submissions_by_grader_for_index(avenger, %{"notFullyGraded" => "true"})
      submissions_from_res = res[:data][:submissions]
      Enum.each(submissions_from_res, fn s ->
        assert s.question_count > s.graded_count
      end)
    end
  end

  defp get_answer_relative_scores(answers) do
    answers |> Enum.map(fn ans -> ans.relative_score end)
  end

  defp get_question_ids(questions) do
    questions |> Enum.map(fn q -> q.id end) |> Enum.sort()
  end

  defp expected_top_relative_scores(top_x, token_divider) do
    # "return 0;" in the factory has 3 token
    10..0
    |> Enum.to_list()
    |> Enum.map(fn score -> 10 * score - :math.pow(2, 3 / token_divider) end)
    |> Enum.take(top_x)
  end
end
