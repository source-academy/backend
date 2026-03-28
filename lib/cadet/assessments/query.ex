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
        question_count: q.question_count,
        has_llm_questions: q.has_llm_questions
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
      question_count: count(q.id),
      has_llm_questions:
        fragment(
          "bool_or(? ->> 'llm_prompt' IS NOT NULL AND ? ->> 'llm_prompt' != '')",
          q.question,
          q.question
        )
    })
  end

  @doc """
  Checks if a course has any assessments with LLM content.
  Returns true if any assessment has questions with llm_prompt or llm_assessment_prompt.
  """
  @spec course_has_llm_content?(integer()) :: boolean()
  def course_has_llm_content?(course_id) when is_ecto_id(course_id) do
    Assessment
    |> where(course_id: ^course_id)
    |> join(:left, [a], q in subquery(assessments_aggregates()), on: a.id == q.assessment_id)
    |> select([a, q], %{
      has_llm_questions: q.has_llm_questions,
      llm_assessment_prompt: a.llm_assessment_prompt
    })
    |> Repo.all()
    |> Enum.any?(fn assessment ->
      assessment.has_llm_questions == true or
        assessment.llm_assessment_prompt not in [nil, ""]
    end)
  end
end
