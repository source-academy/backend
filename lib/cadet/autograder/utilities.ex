defmodule Cadet.Autograder.Utilities do
  @moduledoc """
  This module defines functions that support the autograder functionality.
  """
  use Cadet, :context

  import Ecto.Query
  import Cadet.Factory

  alias Ecto.Multi

  alias Cadet.Accounts.User
  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}

  # TODO: DELETE THIS
  def seed_assessments do
    assessments =
      Enum.map(1..3, fn _ ->
        insert(:assessment, %{
          is_published: true,
          open_at: Timex.shift(Timex.now(), days: -5),
          close_at: Timex.shift(Timex.now(), hours: -4),
          type: :mission
        })
      end)

    Enum.map(assessments, &insert_list(3, :programming_question, %{assessment: &1}))
  end

  def process_all_due_yesterday do
    for assessment <- fetch_assessments_due_yesterday() do
      assessment.id
      |> fetch_submissions()
      |> Enum.map(fn item = %{student_id: student_id, submission: submission} ->
        if submission do
          item
        else
          %{
            student_id: student_id,
            submission: insert_empty_submission(%{student_id: student_id, assessment: assessment})
          }
        end
      end)
      |> Enum.each(fn %{submission: submission} ->
        process_individual_submission(submission, assessment)
      end)
    end
  end

  def process_individual_submission(
        %Submission{id: submission_id},
        %Assessment{questions: questions}
      ) do
    answers =
      Answer
      |> where(submission_id: ^submission_id)
      |> order_by(:question_id)
      |> Repo.all()

    process_submission_question_answer_lists(submission_id, questions, answers, Multi.new())
  end

  # TODO: IMPLEMENT THIS
  def dispatch_answer(answer, question) do
    IO.puts("Dispatched answer: answer_id: #{answer.id}, question_id: #{question.id}")
  end

  def insert_empty_answer(submission_id, %Question{id: question_id, type: question_type}, multi) do
    Multi.insert(
      multi,
      "question#{question_id}",
      %Answer{}
      |> Answer.changeset(%{
        answer: %{code: "Question not answered by student."},
        question_id: question_id,
        submission_id: submission_id,
        type: question_type
      })
      |> Answer.autograding_changeset(%{grade: 0, autograding_status: :success})
    )
  end

  def insert_empty_submission(%{student_id: student_id, assessment: assessment}) do
    %Submission{}
    |> Submission.changeset(%{
      student_id: student_id,
      assessment: assessment,
      status: :submitted
    })
    |> Repo.insert!()
  end

  def fetch_submissions(assessment_id) when is_ecto_id(assessment_id) do
    User
    |> where(role: "student")
    |> join(:left, [u], s in Submission, u.id == s.student_id)
    |> where([_, s], s.assessment_id == ^assessment_id)
    |> select([u, s], %{student_id: u.id, submission: s})
    |> Repo.all()
  end

  def fetch_assessments_due_yesterday do
    Assessment
    |> where(is_published: true)
    |> where([a], a.close_at < ^Timex.now() and a.close_at >= ^Timex.shift(Timex.now(), days: -1))
    |> where([a], a.type == "mission")
    |> join(:inner, [a], q in assoc(a, :questions))
    |> preload([_, q], questions: q)
    |> Repo.all()
    |> Enum.map(&sort_assessment_questions(&1))
  end

  def sort_assessment_questions(assessment = %Assessment{}) do
    sorted_questions = Enum.sort_by(assessment.questions, & &1.id)
    Map.put(assessment, :questions, sorted_questions)
  end

  def process_submission_question_answer_lists(
        submission_id,
        [question = %Question{} | question_tail],
        answers = [answer = %Answer{} | answer_tail],
        multi
      ) do
    if question.id == answer.question_id do
      dispatch_answer(answer, question)
      process_submission_question_answer_lists(submission_id, question_tail, answer_tail, multi)
    else
      process_submission_question_answer_lists(
        submission_id,
        question_tail,
        answers,
        insert_empty_answer(submission_id, question, multi)
      )
    end
  end

  def process_submission_question_answer_lists(
        submission_id,
        [question = %Question{} | question_tail],
        [],
        multi
      ) do
    process_submission_question_answer_lists(
      submission_id,
      question_tail,
      [],
      insert_empty_answer(submission_id, question, multi)
    )
  end

  def process_submission_question_answer_lists(_, [], [], multi) do
    Repo.transaction(multi)
  end
end
