defmodule Cadet.Assessments.Query do
  @moduledoc """
  Generate queries related to the Assessments context
  """
  use Cadet, :context

  import Ecto.Query

  alias Cadet.Assessments.{Assessment, Question}

  @doc """
  Returns a query with the following bindings:
  [assessments_with_xp, questions]
  """
  @spec all_assessments_with_aggregates(integer()) :: Ecto.Query.t()
  def all_assessments_with_aggregates(course_id) when is_ecto_id(course_id) do
    Assessment
    |> where(course_id: ^course_id)
    |> join(:inner, [a], q in subquery(assessments_aggregates()), on: a.id == q.assessment_id)
    |> select([a, q], %Assessment{
      a
      | max_xp: q.max_xp,
        question_count: q.question_count
    })
  end

  @doc """
  Returns a query with the following bindings:
  [assessments_with_xp, questions]
  """
  @spec all_assessments_with_max_xp :: Ecto.Query.t()
  def all_assessments_with_max_xp do
    Assessment
    |> join(:inner, [a], q in subquery(assessments_max_xp()), on: a.id == q.assessment_id)
    |> select([a, q], %Assessment{a | max_xp: q.max_xp})
  end

  @spec assessments_max_xp :: Ecto.Query.t()
  def assessments_max_xp do
    Question
    |> group_by(:assessment_id)
    |> select([q], %{assessment_id: q.assessment_id, max_xp: sum(q.max_xp)})
  end

  @spec assessments_aggregates :: Ecto.Query.t()
  def assessments_aggregates do
    Question
    |> group_by(:assessment_id)
    |> select([q], %{
      assessment_id: q.assessment_id,
      max_xp: sum(q.max_xp),
      question_count: count(q.id)
    })
  end
end
