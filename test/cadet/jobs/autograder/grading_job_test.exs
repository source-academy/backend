defmodule Cadet.Autograder.GradingJobTest do
  use Cadet.DataCase

  import Mock
  import Ecto.Query

  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}
  alias Cadet.Autograder.{GradingJob, LambdaWorker, Utilities}

  defmacrop assert_dispatched(answer_question_list) do
    quote do
      for {answer, question} <- unquote(answer_question_list) do
        assert_called(
          Que.add(LambdaWorker, %{
            question: Repo.get(Question, question.id),
            answer: Repo.get(Answer, answer.id)
          })
        )
      end
    end
  end

  describe "all programming questions" do
    setup do
      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: :mission
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :programming_question, %{assessment: assessment})
        end

      %{assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions answered, enqueues all jobs", %{
      assessments: assessments
    } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:user, %{role: :student})

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

        GradingJob.grade_all_due_yesterday()
        submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
        questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
        answers = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

        for submission <- submissions do
          assert Repo.get(Submission, submission.id).status == :submitted
        end

        assert_dispatched(Enum.zip(answers, questions))
      end
    end

    test "all assessments attempted, updates all submission statuses", %{
      assessments: assessments
    } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:user, %{role: :student})

        submissions =
          Enum.map(assessments, fn {assessment, _} ->
            insert(:submission, %{student: student, assessment: assessment, status: :attempted})
          end)

        GradingJob.grade_all_due_yesterday()

        for submission <- submissions do
          assert Repo.get(Submission, submission.id).status == :submitted
        end
      end
    end

    test "all assessments unattempted, creates submissions", %{
      assessments: assessments
    } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:user, %{role: :student})

        GradingJob.grade_all_due_yesterday()

        for {assessment, _} <- assessments do
          submission =
            Submission
            |> where(student_id: ^student.id)
            |> where(assessment_id: ^assessment.id)
            |> Repo.one()

          assert submission
          assert submission.status == :submitted
        end
      end
    end

    test "all assessments attempting, no questions answered, inserts empty answers", %{
      assessments: assessments
    } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:user, %{role: :student})

        for {assessment, _} <- assessments do
          insert(:submission, %{student: student, assessment: assessment, status: :attempting})
        end

        GradingJob.grade_all_due_yesterday()

        answers =
          Submission
          |> where(student_id: ^student.id)
          |> join(:inner, [s], a in assoc(s, :answers))
          |> preload([_, a], answers: a)
          |> Repo.all()
          |> Enum.map(&Map.from_struct(&1))
          |> Enum.flat_map(fn submission -> submission.answers end)

        assert Enum.count(answers) == 9

        for answer <- answers do
          assert answer.grade == 0
          assert answer.autograding_status == :success
          assert answer.answer == %{"code" => "//Question not answered by student."}
          assert answer.comment == "Question not attempted by student"
        end
      end
    end

    # Test unanswered question behaviour of two finger walk
    test "all assessments attempting, first question unanswered, " <>
           "insert empty answer, dispatch submitted answers",
         %{
           assessments: assessments
         } do
      with_mock Que, add: fn _, _ -> nil end do
        student = insert(:user, %{role: :student})

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

        GradingJob.grade_all_due_yesterday()
        submissions = Enum.map(submissions_answers, fn {submission, _} -> submission end)
        questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
        questions_answered = Enum.drop_every(questions, 3)
        answers_submitted = Enum.flat_map(submissions_answers, fn {_, answers} -> answers end)

        for submission <- submissions do
          assert Repo.get(Submission, submission.id).status == :submitted
        end

        assert_dispatched(Enum.zip(answers_submitted, questions_answered))
        unanswered_question_ids = questions |> Enum.take_every(3) |> Enum.map(& &1.id)

        inserted_empty_answers =
          Submission
          |> where(student_id: ^student.id)
          |> join(:inner, [s], a in assoc(s, :answers))
          |> preload([_, a], answers: a)
          |> Repo.all()
          |> Enum.map(&Map.from_struct(&1))
          |> Enum.flat_map(& &1.answers)
          |> Enum.filter(&(&1.question_id in unanswered_question_ids))

        for answer <- inserted_empty_answers do
          assert answer.grade == 0
          assert answer.autograding_status == :success
          assert answer.answer == %{"code" => "//Question not answered by student."}
          assert answer.comment == "Question not attempted by student"
        end
      end
    end
  end

  describe "all mcq questions" do
    setup do
      assessments =
        insert_list(3, :assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: :mission
        })

      questions =
        for assessment <- assessments do
          insert_list(3, :mcq_question, %{max_grade: 20, assessment: assessment})
        end

      %{assessments: Enum.zip(assessments, questions)}
    end

    test "all assessments attempted, all questions answered, enqueues all jobs", %{
      assessments: assessments
    } do
      student = insert(:user, %{role: :student})

      for {assessment, _} <- assessments do
        insert(:submission, %{student: student, assessment: assessment, status: :attempting})
      end

      GradingJob.grade_all_due_yesterday()

      answers =
        Submission
        |> where(student_id: ^student.id)
        |> join(:inner, [s], a in assoc(s, :answers))
        |> preload([_, a], answers: a)
        |> Repo.all()
        |> Enum.map(&Map.from_struct(&1))
        |> Enum.flat_map(fn submission -> submission.answers end)

      assert Enum.count(answers) == 9

      for answer <- answers do
        assert answer.grade == 0
        assert answer.autograding_status == :success
        assert answer.answer == %{"choice_id" => 0}
        assert answer.comment == "Question not attempted by student"
      end
    end

    test "all assessments attempted, all questions answered, grades all questions", %{
      assessments: assessments
    } do
      student = insert(:user, %{role: :student})

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

      for submission <- submissions do
        assert Repo.get(Submission, submission.id).status == :submitted
      end

      for {answer, question} <- Enum.zip(answers, questions) do
        answer_db = Repo.get(Answer, answer.id)

        if answer_db.answer["choice_id"] == 0 do
          assert answer_db.grade == question.max_grade
        else
          assert answer_db.grade == 0
        end

        assert answer_db.autograding_status == :success
      end
    end
  end
end
