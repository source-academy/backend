defmodule Cadet.Autograder.GradingJobTest do
  use Cadet.DataCase

  import Mock
  import Ecto.Query

  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}
  alias Cadet.Autograder.{GradingJob, LambdaWorker, Utilities}

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

      for {answer, question} <- Enum.zip(answers, questions) do
        assert_called(
          Que.add(
            LambdaWorker,
            %{
              question: get_question_for_mock(question.id),
              answer: get_answer_for_mock(answer.id)
            }
          )
        )
      end
    end
  end

  # CHANGE THIS AT YOUR PERIL
  defp get_question_for_mock(id) do
    Question
    |> where(id: ^id)
    |> select([
      :assessment_id,
      :grading_library,
      :id,
      :library,
      :inserted_at,
      :question,
      :type,
      :updated_at,
      :title,
      :max_grade
    ])
    |> Repo.one()
  end

  defp get_answer_for_mock(id) do
    Answer
    |> where(id: ^id)
    |> select([
      :id,
      :answer,
      :grade,
      :inserted_at,
      :question_id,
      :submission_id,
      :updated_at,
      :adjustment,
      :autograding_status
    ])
    |> Repo.one()
  end
end
