defmodule Cadet.Autograder.GradingJob do
  @moduledoc """
  This module contains logic for finding answers to be graded and
  processing/dispatching them as appropriate
  """
  use Cadet, :context

  import Ecto.Query

  require Logger

  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}
  alias Cadet.Autograder.Utilities

  def close_and_make_empty_submission(assessment = %Assessment{id: id}) do
    id
    |> Utilities.fetch_submissions()
    |> Enum.map(fn %{student_id: student_id, submission: submission} ->
      if submission do
        update_submission_status_to_submitted(submission)
      else
        insert_empty_submission(%{student_id: student_id, assessment: assessment})
      end
    end)
  end

  def grade_all_due_yesterday do
    Logger.info("Started autograding")

    for assessment <- Utilities.fetch_assessments_due_yesterday() do
      assessment
      |> close_and_make_empty_submission()
      |> Enum.each(fn submission ->
        Cadet.Accounts.Notifications.write_notification_when_student_submits(submission)
        grade_individual_submission(submission, assessment)
      end)
    end
  end

  @doc """
  Exposed as public function in case future mix tasks are needed to regrade
  certain submissions. Manual grading can also be triggered from iex with this
  function.

  Takes in submission to be graded. Submission will be graded regardless of its
  assessment's close_by date or submission status.

  Every answer will be regraded regardless of its current autograding status.
  """
  def force_grade_individual_submission(submission = %Submission{}) do
    assessment =
      if Ecto.assoc_loaded?(submission.assessment) do
        submission.assessment
      else
        submission |> Repo.preload(:assessment) |> Map.get(:assessment)
      end

    assessment = preprocess_assessment_for_grading(assessment)
    grade_individual_submission(submission, assessment, true)
  end

  # This function requires that assessment questions are already preloaded in sorted
  # order for autograding to function correctly.
  defp grade_individual_submission(
         %Submission{id: submission_id},
         %Assessment{questions: questions},
         regrade \\ false
       ) do
    answers =
      Answer
      |> where(submission_id: ^submission_id)
      |> order_by(:question_id)
      |> Repo.all()

    grade_submission_question_answer_lists(
      submission_id,
      questions,
      answers,
      regrade
    )
  end

  defp preprocess_assessment_for_grading(assessment = %Assessment{}) do
    if Ecto.assoc_loaded?(assessment.questions) do
      Utilities.sort_assessment_questions(assessment)
    else
      questions =
        Question
        |> where(assessment_id: ^assessment.id)
        |> order_by(:id)
        |> Repo.all()

      Map.put(assessment, :questions, questions)
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

  defp update_submission_status_to_submitted(submission = %Submission{}) do
    submission
    |> Submission.changeset(%{status: :submitted})
    |> Repo.update!()
  end

  defp grade_answer(answer = %Answer{}, question = %Question{type: type}) do
    case type do
      :programming -> Utilities.dispatch_programming_answer(answer, question)
      :mcq -> grade_mcq_answer(answer, question)
    end
  end

  def grade_mcq_answer(answer = %Answer{}, question = %Question{question: question_content}) do
    correct_choice =
      question_content["choices"]
      |> Enum.find(&Map.get(&1, "is_correct"))
      |> Map.get("choice_id")

    grade = if answer.answer["choice_id"] == correct_choice, do: question.max_grade, else: 0

    xp =
      if question.max_grade == 0,
        do: 0,
        else: Integer.floor_div(question.max_xp * grade, question.max_grade)

    answer
    |> Answer.autograding_changeset(%{
      grade: grade,
      xp: xp,
      autograding_status: :success
    })
    |> Repo.update()
  end

  defp insert_empty_answer(
         submission_id,
         %Question{id: question_id, type: question_type}
       )
       when is_ecto_id(submission_id) do
    answer_content =
      case question_type do
        :programming -> %{code: "// Question was left blank by the student."}
        :mcq -> %{choice_id: 0}
      end

    %Answer{}
    |> Answer.changeset(%{
      answer: answer_content,
      question_id: question_id,
      submission_id: submission_id,
      type: question_type
    })
    |> Answer.autograding_changeset(%{grade: 0, autograding_status: :success})
    |> Repo.insert()
  end

  # Two finger walk down question and answer lists.
  # Both lists MUST be pre-sorted by id and question_id respectively
  defp grade_submission_question_answer_lists(
         submission_id,
         [question = %Question{} | question_tail],
         answers = [answer = %Answer{} | answer_tail],
         regrade
       )
       when is_boolean(regrade) and is_ecto_id(submission_id) do
    if question.id == answer.question_id do
      if regrade || answer.autograding_status in [:none, :failed] do
        grade_answer(answer, question)
      end

      grade_submission_question_answer_lists(
        submission_id,
        question_tail,
        answer_tail,
        regrade
      )
    else
      insert_empty_answer(submission_id, question)

      grade_submission_question_answer_lists(
        submission_id,
        question_tail,
        answers,
        regrade
      )
    end
  end

  defp grade_submission_question_answer_lists(
         submission_id,
         [question = %Question{} | question_tail],
         [],
         regrade
       )
       when is_boolean(regrade) and is_ecto_id(submission_id) do
    insert_empty_answer(submission_id, question)

    grade_submission_question_answer_lists(
      submission_id,
      question_tail,
      [],
      regrade
    )
  end

  defp grade_submission_question_answer_lists(_, [], [], _) do
  end
end
