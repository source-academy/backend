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
          Que.add(
            LambdaWorker,
            %{
              question: Repo.get(Question, question.id),
              answer: Repo.get(Answer, answer.id)
            }
          )
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

  test "all assessments submitted, all questions answered", %{assessments: assessments} do
    with_mock Que, add: fn _, _ -> nil end do
      student = insert(:user, %{role: :student})

      submissions =
        Enum.map(assessments, fn {assessment, questions} ->
          submission = insert(:submission, %{student: student, assessment: assessment})

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
      questions = Enum.flat_map(assessments, fn {_, questions} -> questions end)
      answers = Enum.flat_map(submissions, fn {_, answers} -> answers end)

      assert_dispatched(Enum.zip(answers, questions))
    end
  end
end
