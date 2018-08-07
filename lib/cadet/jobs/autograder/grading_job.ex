defmodule Cadet.Autograder.GradingJob do
  @moduledoc """
  This module contains logic for finding answers to be graded and
  processing/dispatching them as appropriate
  """
  use Cadet, :context

  import Ecto.Query

  alias Ecto.Multi
  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}
  alias Cadet.Autograder.Utilities

  def grade_all_due_yesterday do
    for assessment <- Utilities.fetch_assessments_due_yesterday() do
      assessment.id
      |> Utilities.fetch_submissions()
      |> Enum.map(fn item = %{student_id: student_id, submission: submission} ->
        if submission do
          %{
            student_id: student_id,
            submission: update_submission_status(submission)
          }
        else
          %{
            student_id: student_id,
            submission: insert_empty_submission(%{student_id: student_id, assessment: assessment})
          }
        end
      end)
      |> Enum.each(fn %{submission: submission} ->
        grade_individual_submission(submission, assessment)
      end)
    end
  end

  defp update_submission_status(submission = %Submission{}) do
    submission
    |> Submission.changeset(%{status: :submitted})
    |> Repo.update!()
  end

  # Exposed as public function in case future mix tasks are needed to regrade
  # certain submissions.
  def grade_individual_submission(
        %Submission{id: submission_id},
        %Assessment{questions: questions}
      ) do
    answers =
      Answer
      |> where(submission_id: ^submission_id)
      |> order_by(:question_id)
      |> Repo.all()

    grade_submission_question_answer_lists(submission_id, questions, answers, Multi.new())
  end

  defp grade_answer(answer, question = %{type: type}) do
    case type do
      :programming -> Utilities.dispatch_programming_answer(answer, question)
      :mcq -> grade_mcq_answer(answer, question)
    end
  end

  def grade_mcq_answer(answer, question = %Question{question: question_content}) do
    correct_choice =
      question_content["choices"]
      |> Enum.find(&Map.get(&1, "is_correct"))
      |> Map.get("choice_id")

    grade = if answer.answer["choice_id"] == correct_choice, do: question.max_grade, else: 0

    answer
    |> Answer.autograding_changeset(%{grade: grade, autograding_status: :success})
    |> Repo.update!()
  end

  defp insert_empty_programming_answer(
         submission_id,
         %Question{id: question_id, type: question_type},
         multi
       ) do
    if question_type == :programming do
      Multi.insert(
        multi,
        "question#{question_id}",
        %Answer{}
        |> Answer.changeset(%{
          answer: %{code: "//Question not answered by student."},
          question_id: question_id,
          submission_id: submission_id,
          type: question_type,
          comment: "Question not attempted by student"
        })
        |> Answer.autograding_changeset(%{grade: 0, autograding_status: :success})
      )
    else
      Multi.insert(
        multi,
        "question#{question_id}",
        %Answer{}
        |> Answer.changeset(%{
          answer: %{choice_id: 0},
          question_id: question_id,
          submission_id: submission_id,
          type: question_type,
          comment: "Question not attempted by student"
        })
        |> Answer.autograding_changeset(%{grade: 0, autograding_status: :success})
      )
    end
  end

  defp insert_empty_submission(%{student_id: student_id, assessment: assessment}) do
    %Submission{}
    |> Submission.changeset(%{
      student_id: student_id,
      assessment: assessment,
      status: :submitted
    })
    |> Repo.insert!()
  end

  # Two finger walk down question and answer lists. Both lists MUST be pre-sorted
  defp grade_submission_question_answer_lists(
         submission_id,
         [question = %Question{} | question_tail],
         answers = [answer = %Answer{} | answer_tail],
         multi
       ) do
    if question.id == answer.question_id do
      grade_answer(answer, question)
      grade_submission_question_answer_lists(submission_id, question_tail, answer_tail, multi)
    else
      grade_submission_question_answer_lists(
        submission_id,
        question_tail,
        answers,
        insert_empty_programming_answer(submission_id, question, multi)
      )
    end
  end

  defp grade_submission_question_answer_lists(
         submission_id,
         [question = %Question{} | question_tail],
         [],
         multi
       ) do
    grade_submission_question_answer_lists(
      submission_id,
      question_tail,
      [],
      insert_empty_programming_answer(submission_id, question, multi)
    )
  end

  defp grade_submission_question_answer_lists(_, [], [], multi) do
    Repo.transaction(multi)
  end
end
