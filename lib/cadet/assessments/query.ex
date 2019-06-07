defmodule Cadet.Assessments.Query do
  @moduledoc """
  Generate queries related to the Assessments context
  """
  import Ecto.Query

  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}

  @doc """
  Returns a query with the following bindings:
  [submissions_with_xp_and_grade, answers]
  """
  @spec all_submissions_with_xp_and_grade :: Ecto.Query.t()
  def all_submissions_with_xp_and_grade do
    Submission
    |> join(:inner, [s], q in subquery(submissions_xp_and_grade()), on: s.id == q.submission_id)
    |> select([s, q], %Submission{
      s
      | xp: q.xp,
        xp_adjustment: q.xp_adjustment,
        grade: q.grade,
        adjustment: q.adjustment
    })
  end

  @doc """
  Returns a query with the following bindings:
  [submissions_with_xp, answers]
  """
  @spec all_submissions_with_xp :: Ecto.Query.t()
  def all_submissions_with_xp do
    Submission
    |> join(:inner, [s], q in subquery(submissions_xp()), on: s.id == q.submission_id)
    |> select([s, q], %Submission{s | xp: q.xp, xp_adjustment: q.xp_adjustment})
  end

  @doc """
  Returns a query with the following bindings:
  [submissions_with_grade, answers]
  """
  @spec all_submissions_with_grade :: Ecto.Query.t()
  def all_submissions_with_grade do
    Submission
    |> join(:inner, [s], q in subquery(submissions_grade()), on: s.id == q.submission_id)
    |> select([s, q], %Submission{s | grade: q.grade, adjustment: q.adjustment})
  end

  @doc """
  Returns a query with the following bindings:
  [assessments_with_xp_and_grade, questions]
  """
  @spec all_assessments_with_max_xp_and_grade :: Ecto.Query.t()
  def all_assessments_with_max_xp_and_grade do
    Assessment
    |> join(:inner, [a], q in subquery(assessments_max_xp_and_grade()),
      on: a.id == q.assessment_id
    )
    |> select([a, q], %Assessment{a | max_grade: q.max_grade, max_xp: q.max_xp})
  end

  @doc """
  Returns a query with the following bindings:
  [assessments_with_grade, questions]
  """
  @spec all_assessments_with_max_grade :: Ecto.Query.t()
  def all_assessments_with_max_grade do
    Assessment
    |> join(:inner, [a], q in subquery(assessments_max_grade()), on: a.id == q.assessment_id)
    |> select([a, q], %Assessment{a | max_grade: q.max_grade})
  end

  @spec submissions_xp_and_grade :: Ecto.Query.t()
  def submissions_xp_and_grade do
    Answer
    |> group_by(:submission_id)
    |> select([a], %{
      submission_id: a.submission_id,
      grade: sum(a.grade),
      adjustment: sum(a.adjustment),
      xp: sum(a.xp),
      xp_adjustment: sum(a.xp_adjustment)
    })
  end

  @spec submissions_grade :: Ecto.Query.t()
  def submissions_grade do
    Answer
    |> group_by(:submission_id)
    |> select([a], %{
      submission_id: a.submission_id,
      grade: sum(a.grade),
      adjustment: sum(a.adjustment)
    })
  end

  @spec submissions_xp :: Ecto.Query.t()
  def submissions_xp do
    Answer
    |> group_by(:submission_id)
    |> select([a], %{
      submission_id: a.submission_id,
      xp: sum(a.xp),
      xp_adjustment: sum(a.xp_adjustment)
    })
  end

  @spec assessments_max_grade :: Ecto.Query.t()
  def assessments_max_grade do
    Question
    |> group_by(:assessment_id)
    |> select([q], %{assessment_id: q.assessment_id, max_grade: sum(q.max_grade)})
  end

  @spec assessments_max_xp_and_grade :: Ecto.Query.t()
  def assessments_max_xp_and_grade do
    Question
    |> group_by(:assessment_id)
    |> select([q], %{
      assessment_id: q.assessment_id,
      max_grade: sum(q.max_grade),
      max_xp: sum(q.max_xp)
    })
  end

  def assessments_question_count do
    Question
    |> group_by(:assessment_id)
    |> select([q], %{
      assessment_id: q.assessment_id,
      count: count(q.id)
    })
  end

  def submissions_graded_count do
    Answer
    |> where([a], not is_nil(a.grader_id))
    |> group_by(:submission_id)
    |> select([a], %{
      submission_id: a.submission_id,
      count: count(a.id)
    })
  end
end
