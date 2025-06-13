defmodule Cadet.Autograder.GradingJobTest do
  use Cadet.DataCase

  import Mock
  import Ecto.Query

  alias Que.Persistence, as: JobsQueue

  alias Cadet.Accounts.Notification
  alias Cadet.Assessments.{Answer, Question, Submission, SubmissionVotes}
  alias Cadet.Autograder.{GradingJob, LambdaWorker}

  defp assert_dispatched(answer_question_list) do
    for {answer, question} <- answer_question_list do
      assert_called(
        Que.add(LambdaWorker, %{
          question: Repo.get(Question, question.id),
          answer: Repo.get(Answer, answer.id)
        })
      )
    end
  end

  describe "#force_grade_individual_submission, all programming questions" do
    setup do
      course = insert(:course)

      assessment_config =
        insert(:assessment_config, %{
          course: course,
          is_grading_auto_published: true,
          is_manually_graded: false
        })

      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          config: assessment_config,
          course: course
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :programming_question, %{assessment: assessment})
        end

      %{course: course, assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions graded, assocs preloaded, should enqueue all jobs",
         %{course: course, assessments: assessments} do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:course_registration, %{course: course, role: :student})

        [{assessment, questions} | _] = assessments

        submission =
          insert(:submission, %{student: student, assessment: assessment, status: :attempted})

        submission = Repo.preload(submission, assessment: [:questions])

        answers =
          Enum.map(questions, fn question ->
            insert(:answer, %{
              question: question,
              submission: submission,
              answer: build(:programming_answer),
              autograding_status: :success
            })
          end)

        GradingJob.force_grade_individual_submission(submission)

        for answer <- answers do
          assert Repo.get(Answer, answer.id).autograding_status == :processing
        end

        assert_dispatched(Enum.zip(answers, questions))
      end
    end

    test "all assessments attempted, all questions graded, no assocs preloaded, " <>
           "should enqueue all jobs",
         %{course: course, assessments: assessments} do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:course_registration, %{course: course, role: :student})

        [{assessment, questions} | _] = assessments

        submission =
          insert(:submission, %{student: student, assessment: assessment, status: :attempted})

        answers =
          Enum.map(questions, fn question ->
            insert(:answer, %{
              question: question,
              submission: submission,
              answer: build(:programming_answer),
              autograding_status: :success
            })
          end)

        submission_db = Repo.get(Submission, submission.id)

        GradingJob.force_grade_individual_submission(submission_db)

        for answer <- answers do
          assert Repo.get(Answer, answer.id).autograding_status == :processing
        end

        assert_dispatched(Enum.zip(answers, questions))
      end
    end
  end

  describe "#grade_all_due_yesterday, all programming questions" do
    setup do
      course = insert(:course)
      assessment_config = insert(:assessment_config, %{course: course})

      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          config: assessment_config,
          course: course
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :programming_question, %{assessment: assessment})
        end

      %{course: course, assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions answered, should enqueue all jobs", %{
      course: course,
      assessments: assessments
    } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:course_registration, %{course: course, role: :student})

        submissions_answers =
          Enum.map(assessments, fn {assessment, questions} ->
            submission =
              insert(:submission, %{student: student, assessment: assessment, status: :attempted})

            answers =
              Enum.map(questions, fn question ->
                insert(:answer, %{
                  question: question,
                  submission: submission,
                  answer: build(:programming_answer)
                })
              end)

            {submission, answers}
          end)

        submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
        questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
        answers = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

        GradingJob.grade_all_due_yesterday()

        for submission <- submissions do
          assert Repo.get(Submission, submission.id).status == :submitted
        end

        for answer <- answers do
          assert Repo.get(Answer, answer.id).autograding_status == :processing
        end

        assert_dispatched(Enum.zip(answers, questions))
      end
    end

    test "all assessments attempted, all questions graded, should not do anything", %{
      course: course,
      assessments: assessments
    } do
      student = insert(:course_registration, %{course: course, role: :student})

      Enum.map(assessments, fn {assessment, questions} ->
        submission =
          insert(:submission, %{student: student, assessment: assessment, status: :attempted})

        Enum.map(questions, fn question ->
          insert(:answer, %{
            question: question,
            submission: submission,
            answer: build(:programming_answer),
            autograding_status: :success
          })
        end)
      end)

      GradingJob.grade_all_due_yesterday()

      assert Enum.empty?(JobsQueue.all())
    end

    test "all assessments attempted, should update all submission statuses and create notifications",
         %{
           course: course,
           assessments: assessments
         } do
      with_mock Que, add: fn _, _ -> nil end do
        group = insert(:group, %{course: course})

        student =
          insert(:course_registration, %{course: course, role: :student, group_id: group.id})

        submissions =
          Enum.map(assessments, fn {assessment, _} ->
            insert(:submission, %{student: student, assessment: assessment, status: :attempted})
          end)

        GradingJob.grade_all_due_yesterday()

        for %Submission{id: id} <- submissions do
          assert Repo.get(Submission, id).status == :submitted

          refute Notification
                 |> where(submission_id: ^id, type: ^:submitted)
                 |> Repo.one()
                 |> is_nil()
        end
      end
    end

    test "all assessments submitted, should not create notifications",
         %{
           course: course,
           assessments: assessments
         } do
      with_mock Que, add: fn _, _ -> nil end do
        group = insert(:group, %{course: course})

        student =
          insert(:course_registration, %{course: course, role: :student, group_id: group.id})

        submissions =
          Enum.map(assessments, fn {assessment, _} ->
            insert(:submission, %{student: student, assessment: assessment, status: :submitted})
          end)

        GradingJob.grade_all_due_yesterday()

        for %Submission{id: id} <- submissions do
          assert Notification
                 |> where(submission_id: ^id, type: ^:submitted)
                 |> Repo.one()
                 |> is_nil()
        end
      end
    end

    test "all assessments unattempted, should create submissions", %{
      course: course,
      assessments: assessments
    } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:course_registration, %{course: course, role: :student})

        GradingJob.grade_all_due_yesterday()

        for {assessment, _} <- assessments do
          submission =
            Submission
            |> where(student_id: ^student.id)
            |> where(assessment_id: ^assessment.id)
            |> Repo.one()

          assert submission && submission.status == :submitted
        end
      end
    end

    test "all assessments attempting, no questions answered, " <>
           "should insert empty answers, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      for {assessment, _} <- assessments do
        insert(:submission, %{student: student, assessment: assessment, status: :attempting})
      end

      GradingJob.grade_all_due_yesterday()

      answers =
        Submission
        |> where(student_id: ^student.id)
        |> join(:inner, [s], a in assoc(s, :answers))
        |> select([_, a], a)
        |> Repo.all()

      assert Enum.count(answers) == 9

      for answer <- answers do
        assert answer.autograding_status == :success
        assert answer.answer == %{"code" => "// Question was left blank by the student."}
      end

      assert Enum.empty?(JobsQueue.all())
    end

    # Test unanswered question behaviour of two finger walk
    test "all assessments attempting, first question unanswered, " <>
           "should insert empty answer, should dispatch submitted answers",
         %{
           course: course,
           assessments: assessments
         } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:course_registration, %{course: course, role: :student})

        # Do not answer first question in each assessment
        submissions_answers =
          Enum.map(assessments, fn {assessment, [_ | questions]} ->
            submission =
              insert(:submission, %{student: student, assessment: assessment, status: :attempted})

            answers =
              Enum.map(questions, fn question ->
                insert(:answer, %{
                  question: question,
                  submission: submission,
                  answer: build(:programming_answer)
                })
              end)

            {submission, answers}
          end)

        submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
        questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
        questions_answered = Enum.drop_every(questions, 3)
        answers_submitted = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

        GradingJob.grade_all_due_yesterday()

        for submission <- submissions do
          assert Repo.get(Submission, submission.id).status == :submitted
        end

        for answer <- answers_submitted do
          assert Repo.get(Answer, answer.id).autograding_status == :processing
        end

        assert_dispatched(Enum.zip(answers_submitted, questions_answered))
        unanswered_question_ids = questions |> Enum.take_every(3) |> Enum.map(& &1.id)

        inserted_empty_answers =
          Submission
          |> where(student_id: ^student.id)
          |> join(:inner, [s], a in assoc(s, :answers))
          |> select([_, a], a)
          |> Repo.all()
          |> Enum.filter(&(&1.question_id in unanswered_question_ids))

        for answer <- inserted_empty_answers do
          assert answer.xp == 0
          assert answer.autograding_status == :success
          assert answer.answer == %{"code" => "// Question was left blank by the student."}
        end
      end
    end

    test "all assessments attempted, all questions answered, instance raced, should not do anything",
         %{
           course: course,
           assessments: assessments
         } do
      with_mock Cadet.Jobs.Log, log_execution: fn _name, _period -> false end do
        student = insert(:course_registration, %{course: course, role: :student})

        submissions_answers =
          Enum.map(assessments, fn {assessment, questions} ->
            submission =
              insert(:submission, %{student: student, assessment: assessment, status: :attempted})

            answers =
              Enum.map(questions, fn question ->
                insert(:answer, %{
                  question: question,
                  submission: submission,
                  answer: build(:programming_answer)
                })
              end)

            {submission, answers}
          end)

        submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
        answers = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

        GradingJob.grade_all_due_yesterday()

        for submission <- submissions do
          assert Repo.get(Submission, submission.id).status == :attempted
        end

        for answer <- answers do
          assert Repo.get(Answer, answer.id).autograding_status == :none
        end

        assert Enum.empty?(JobsQueue.all())
      end
    end
  end

  describe "#grade_all_due_yesterday, all mcq questions, grading set to auto publish" do
    setup do
      course = insert(:course)

      assessment_config =
        insert(:assessment_config, %{
          course: course,
          is_grading_auto_published: true,
          is_manually_graded: false
        })

      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          config: assessment_config,
          course: course
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :mcq_question, %{max_xp: 200, assessment: assessment})
        end

      %{course: course, assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions unanswered, " <>
           "should insert empty answers, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions =
        Enum.map(assessments, fn {assessment, _} ->
          insert(:submission, %{student: student, assessment: assessment, status: :attempting})
        end)

      GradingJob.grade_all_due_yesterday()

      answers =
        Submission
        |> where(student_id: ^student.id)
        |> join(:inner, [s], a in assoc(s, :answers))
        |> select([_, a], a)
        |> Repo.all()

      assert Enum.count(answers) == 9

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == true
      end)

      for answer <- answers do
        assert answer.xp == 0
        assert answer.autograding_status == :success
        assert answer.answer == %{"choice_id" => 0}
      end

      assert Enum.empty?(JobsQueue.all())
    end

    test "all assessments attempted, all questions answered, " <>
           "should grade all questions, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions_answers =
        Enum.map(assessments, fn {assessment, questions} ->
          submission =
            insert(:submission, %{student: student, assessment: assessment, status: :attempted})

          answers =
            Enum.map(questions, fn question ->
              insert(:answer, %{
                question: question,
                submission: submission,
                answer: build(:mcq_answer)
              })
            end)

          {submission, answers}
        end)

      GradingJob.grade_all_due_yesterday()
      submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
      questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
      answers = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == true
      end)

      for {answer, question} <- Enum.zip(answers, questions) do
        answer_db = Repo.get(Answer, answer.id)

        # seeded questions have correct choice as 0
        if answer_db.answer["choice_id"] == 0 do
          assert answer_db.xp == question.max_xp
        else
          assert answer_db.xp == 0
        end

        assert answer_db.autograding_status == :success
      end

      assert Enum.empty?(JobsQueue.all())
    end
  end

  describe "#grade_all_due_yesterday, all mcq questions, grading set to not auto publish" do
    setup do
      course = insert(:course)

      assessment_config =
        insert(:assessment_config, %{course: course, is_grading_auto_published: false})

      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          config: assessment_config,
          course: course
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :mcq_question, %{max_xp: 200, assessment: assessment})
        end

      %{course: course, assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions unanswered, " <>
           "should insert empty answers, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions =
        Enum.map(assessments, fn {assessment, _} ->
          insert(:submission, %{student: student, assessment: assessment, status: :attempting})
        end)

      GradingJob.grade_all_due_yesterday()

      answers =
        Submission
        |> where(student_id: ^student.id)
        |> join(:inner, [s], a in assoc(s, :answers))
        |> select([_, a], a)
        |> Repo.all()

      assert Enum.count(answers) == 9

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == false
      end)

      for answer <- answers do
        assert answer.xp == 0
        assert answer.autograding_status == :success
        assert answer.answer == %{"choice_id" => 0}
      end

      assert Enum.empty?(JobsQueue.all())
    end

    test "all assessments attempted, all questions answered, " <>
           "should grade all questions, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions_answers =
        Enum.map(assessments, fn {assessment, questions} ->
          submission =
            insert(:submission, %{student: student, assessment: assessment, status: :attempted})

          answers =
            Enum.map(questions, fn question ->
              insert(:answer, %{
                question: question,
                submission: submission,
                answer: build(:mcq_answer)
              })
            end)

          {submission, answers}
        end)

      GradingJob.grade_all_due_yesterday()
      submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
      questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
      answers = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == false
      end)

      for {answer, question} <- Enum.zip(answers, questions) do
        answer_db = Repo.get(Answer, answer.id)

        # seeded questions have correct choice as 0
        if answer_db.answer["choice_id"] == 0 do
          assert answer_db.xp == question.max_xp
        else
          assert answer_db.xp == 0
        end

        assert answer_db.autograding_status == :success
      end

      assert Enum.empty?(JobsQueue.all())
    end
  end

  describe "#grade_all_due_yesterday, all voting questions, grading set to auto publish" do
    setup do
      course = insert(:course)

      assessment_config =
        insert(:assessment_config, %{
          course: course,
          is_grading_auto_published: true,
          is_manually_graded: false
        })

      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          config: assessment_config,
          course: course
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :voting_question, %{max_xp: 20, assessment: assessment})
        end

      %{course: course, assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions unanswered, " <>
           "should insert empty answers, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions =
        Enum.map(assessments, fn {assessment, _} ->
          insert(:submission, %{student: student, assessment: assessment, status: :attempting})
        end)

      GradingJob.grade_all_due_yesterday()

      answers =
        Submission
        |> where(student_id: ^student.id)
        |> join(:inner, [s], a in assoc(s, :answers))
        |> select([_, a], a)
        |> Repo.all()

      assert Enum.count(answers) == 9

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == true
      end)

      for answer <- answers do
        assert answer.xp == 0
        assert answer.autograding_status == :success
        assert answer.answer == %{"completed" => false}
      end

      assert Enum.empty?(JobsQueue.all())
    end

    test "all assessments attempted, all questions aswered, " <>
           "should grade all questions, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions_answers =
        for {assessment, questions} <- assessments do
          submission =
            insert(:submission, %{student: student, assessment: assessment, status: :attempted})

          answers =
            for question <- questions do
              case Enum.random(0..1) do
                0 -> insert(:submission_vote, %{voter: student, question: question, score: 1})
                1 -> insert(:submission_vote, %{voter: student, question: question})
              end

              insert(:answer, %{
                question: question,
                submission: submission,
                answer: build(:voting_answer)
              })
            end

          {submission, answers}
        end

      GradingJob.grade_all_due_yesterday()
      questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
      submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
      answers = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == true
      end)

      for {question, answer} <- Enum.zip(questions, answers) do
        is_nil_entries =
          SubmissionVotes
          |> where(voter_id: ^student.id)
          |> where(question_id: ^question.id)
          |> where([sv], is_nil(sv.score))
          |> Repo.exists?()

        answer_db = Repo.get(Answer, answer.id)

        if is_nil_entries do
          assert answer_db.xp == 0
        else
          assert answer_db.xp == question.max_xp
        end

        assert answer_db.autograding_status == :success
      end

      assert Enum.empty?(JobsQueue.all())
    end
  end

  describe "#grade_all_due_yesterday, all voting questions, grading set to not auto publish" do
    setup do
      course = insert(:course)

      assessment_config =
        insert(:assessment_config, %{course: course, is_grading_auto_published: false})

      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          config: assessment_config,
          course: course
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :voting_question, %{max_xp: 20, assessment: assessment})
        end

      %{course: course, assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions unanswered, " <>
           "should insert empty answers, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions =
        Enum.map(assessments, fn {assessment, _} ->
          insert(:submission, %{student: student, assessment: assessment, status: :attempting})
        end)

      GradingJob.grade_all_due_yesterday()

      answers =
        Submission
        |> where(student_id: ^student.id)
        |> join(:inner, [s], a in assoc(s, :answers))
        |> select([_, a], a)
        |> Repo.all()

      assert Enum.count(answers) == 9

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == false
      end)

      for answer <- answers do
        assert answer.xp == 0
        assert answer.autograding_status == :success
        assert answer.answer == %{"completed" => false}
      end

      assert Enum.empty?(JobsQueue.all())
    end

    test "all assessments attempted, all questions aswered, " <>
           "should grade all questions, should not enqueue any",
         %{
           course: course,
           assessments: assessments
         } do
      student = insert(:course_registration, %{course: course, role: :student})

      submissions_answers =
        for {assessment, questions} <- assessments do
          submission =
            insert(:submission, %{student: student, assessment: assessment, status: :attempted})

          answers =
            for question <- questions do
              case Enum.random(0..1) do
                0 -> insert(:submission_vote, %{voter: student, question: question, score: 1})
                1 -> insert(:submission_vote, %{voter: student, question: question})
              end

              insert(:answer, %{
                question: question,
                submission: submission,
                answer: build(:voting_answer)
              })
            end

          {submission, answers}
        end

      GradingJob.grade_all_due_yesterday()
      questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
      submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
      answers = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

      Enum.each(submissions, fn submission ->
        submission = Repo.get(Submission, submission.id)
        assert submission.status == :submitted
        assert submission.is_grading_published == false
      end)

      for {question, answer} <- Enum.zip(questions, answers) do
        is_nil_entries =
          SubmissionVotes
          |> where(voter_id: ^student.id)
          |> where(question_id: ^question.id)
          |> where([sv], is_nil(sv.score))
          |> Repo.exists?()

        answer_db = Repo.get(Answer, answer.id)

        if is_nil_entries do
          assert answer_db.xp == 0
        else
          assert answer_db.xp == question.max_xp
        end

        assert answer_db.autograding_status == :success
      end

      assert Enum.empty?(JobsQueue.all())
    end
  end
end
