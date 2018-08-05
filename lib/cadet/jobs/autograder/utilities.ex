defmodule Cadet.Autograder.Utilities do
  @moduledoc """
  This module defines functions that support the autograder functionality.
  """
  use Cadet, :context

  import Ecto.Query
  import Cadet.Factory

  alias Cadet.Accounts.User
  alias Cadet.Assessments.{Assessment, Submission}

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

  def dispatch_answer(answer, question) do
    if question.type == :programming do
      Que.add(Cadet.Autograder.LambdaWorker, %{question: question, answer: answer})
    end
  end

  def fetch_submissions(assessment_id) when is_ecto_id(assessment_id) do
    User
    |> where(role: "student")
    |> join(
      :left,
      [u],
      s in Submission,
      u.id == s.student_id and s.assessment_id == ^assessment_id
    )
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

  defp sort_assessment_questions(assessment = %Assessment{}) do
    sorted_questions = Enum.sort_by(assessment.questions, & &1.id)
    Map.put(assessment, :questions, sorted_questions)
  end
end
