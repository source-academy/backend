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
        assert answer.answer == %{"code" => "Question not answered by student."}
      end
    end
  end
end
