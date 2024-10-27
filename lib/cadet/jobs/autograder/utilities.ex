defmodule Cadet.Autograder.Utilities do
  @moduledoc """
  This module defines functions that support the autograder functionality.
  """
  use Cadet, :context

  require Logger

  import Ecto.Query

  alias Cadet.Accounts.{CourseRegistration, TeamMember}

  alias Cadet.Assessments
  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}

  def dispatch_programming_answer(answer = %Answer{}, question = %Question{}, overwrite \\ false) do
    # This should never fail
    answer =
      answer
      |> Answer.autograding_changeset(%{autograding_status: :processing})
      |> Repo.update!()

    Que.add(Cadet.Autograder.LambdaWorker, %{
      question: question,
      answer: answer,
      overwrite: overwrite
    })
  end

  def fetch_submissions(assessment_id, course_id)
      when is_ecto_id(assessment_id) and is_ecto_id(course_id) do
    if Assessments.is_team_assessment?(assessment_id) do
      fetch_team_submissions(assessment_id, course_id)
    else
      fetch_student_submissions(assessment_id, course_id)
    end
  end

  defp fetch_team_submissions(assessment_id, course_id)
       when is_ecto_id(assessment_id) and is_ecto_id(course_id) do
    CourseRegistration
    |> where(role: "student", course_id: ^course_id)
    |> join(
      :left,
      [cr],
      tm in TeamMember,
      on: cr.id == tm.student_id
    )
    |> join(
      :left,
      [cr, tm],
      s in Submission,
      on: tm.team_id == s.team_id and s.assessment_id == ^assessment_id
    )
    |> select([cr, tm, s], %{student_id: cr.id, submission: s})
    |> Repo.all()
  end

  defp fetch_student_submissions(assessment_id, course_id)
       when is_ecto_id(assessment_id) and is_ecto_id(course_id) do
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
