defmodule Cadet.Assessments.Query do
  @moduledoc """
  Generate queries related to the Assessments context
  """
  import Ecto.Query

  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}

  @doc """
  Returns a query with the following bindings:
  [submissions_with_grade, answers]
  """
  @spec all_submissions_with_grade :: Ecto.Query.t()
  def all_submissions_with_grade do
    Submission
    |> join(:inner, [s], q in subquery(submissions_grade()), s.id == q.submission_id)
    |> select([s, q], %Submission{s | grade: q.grade})
  end

  @doc """
  Returns a query with the following bindings:
  [assessments_with_grade, questions]
  """
  @spec all_assessments_with_max_grade :: Ecto.Query.t()
  def all_assessments_with_max_grade do
    Assessment
    |> join(:inner, [a], q in subquery(assessments_max_grade()), a.id == q.assessment_id)
    |> select([a, q], %Assessment{a | max_grade: q.max_grade})
  end

  @spec submissions_grade :: Ecto.Query.t()
  def submissions_grade do
    Answer
    |> group_by(:submission_id)
    |> select([a], %{
      submission_id: a.submission_id,
      grade: fragment("? + ?", sum(a.grade), sum(a.adjustment))
    })
  end

  @spec assessments_max_grade :: Ecto.Query.t()
  def assessments_max_grade do
    Question
    |> group_by(:assessment_id)
    |> select([q], %{assessment_id: q.assessment_id, max_grade: sum(q.max_grade)})
  end
end
