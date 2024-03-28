defmodule Cadet.Autograder.Utilities do
  @moduledoc """
  This module defines functions that support the autograder functionality.
  """
  use Cadet, :context

  require Logger

  import Ecto.Query

  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}

  def dispatch_programming_answer(
    base_question = %Question{},
    answers = [%Answer{}],
    answer = %Answer{},
    questions = [%Question{}],
    overwrite \\ false) do
    # This should never fail
    answer =
      answer
      |> Answer.autograding_changeset(%{autograding_status: :processing})
      |> Repo.update!()

    Que.add(Cadet.Autograder.LambdaWorker, %{
      base_question: base_question,
      answer: answer,
      questions: questions,
      answers: answers,
      overwrite: overwrite
    })
  end

  def fetch_submissions(assessment_id, course_id) when is_ecto_id(assessment_id) do
    CourseRegistration
    |> where(role: "student", course_id: ^course_id)
    |> join(
      :left,
      [cr],
      s in Submission,
      on: cr.id == s.student_id and s.assessment_id == ^assessment_id
    )
    |> select([cr, s], %{student_id: cr.id, submission: s})
    |> Repo.all()
  end

  def fetch_assessments_due_yesterday do
    Assessment
    |> where(is_published: true)
    |> where([a], a.close_at < ^Timex.now() and a.close_at >= ^Timex.shift(Timex.now(), days: -1))
    |> join(:inner, [a, c], q in assoc(a, :questions))
    |> preload([_, q], questions: q)
    |> Repo.all()
    |> Enum.map(&sort_assessment_questions(&1))
  end

  def sort_assessment_questions(assessment = %Assessment{}) do
    sorted_questions = Enum.sort_by(assessment.questions, & &1.id)
    Map.put(assessment, :questions, sorted_questions)
  end
end
