defmodule Cadet.Assessments.Query do
  @moduledoc """
  Generate queries related to the Assessments context
  """
  import Ecto.Query

  alias Cadet.Assessments.{Answer, Assessment, Question, Submission}

  @spec all_submissions_with_xp :: Submission.t()
  def all_submissions_with_xp do
    Submission
    |> join(:inner, [s], q in subquery(submissions_xp()), s.id == q.submission_id)
    |> select([s, q], %Submission{s | xp: q.xp})
  end

  @spec all_assessments_with_max_xp :: Assessment.t()
  def all_assessments_with_max_xp do
    Assessment
    |> join(:inner, [a], q in subquery(assessments_max_xp()), a.id == q.assessment_id)
    |> select([a, q], %Assessment{a | max_xp: q.max_xp})
  end

  @spec submissions_xp :: %{submission_id: integer(), xp: integer()}
  def submissions_xp do
    Answer
    |> group_by(:submission_id)
    |> select([a], %{
      submission_id: a.submission_id,
      xp: fragment("? + ?", sum(a.xp), sum(a.adjustment))
    })
  end

  @spec assessments_max_xp :: %{assessment_id: integer(), max_xp: integer()}
  def assessments_max_xp do
    Question
    |> group_by(:assessment_id)
    |> select([q], %{assessment_id: q.assessment_id, max_xp: sum(q.max_xp)})
  end
end
