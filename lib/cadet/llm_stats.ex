defmodule Cadet.LLMStats do
  @moduledoc """
  Context module for LLM usage statistics and feedback.
  Provides per-assessment and per-question statistics and feedback management.
  """

  import Ecto.Query
  alias Cadet.Repo
  alias Cadet.Assessments.{Assessment, Question}
  alias Cadet.LLMStats.{LLMUsageLog, LLMFeedback}

  # =====================
  # Usage Logging
  # =====================

  @doc """
  Logs a usage event when "Generate Comments" is invoked.
  """
  def log_usage(attrs) do
    %LLMUsageLog{}
    |> LLMUsageLog.changeset(attrs)
    |> Repo.insert()
  end

  # =====================
  # Assessment-level Statistics
  # =====================

  @doc """
  Returns LLM usage statistics for a specific assessment.

  Returns:
  - total_uses: total "Generate Comments" invocations
  - unique_submissions: unique submissions that had LLM used
  - unique_users: unique users who used the feature
  - questions: per-question breakdown with stats
  - llm_total_cost: Total cost in SGD
  - llm_total_input_tokens: Total standard input tokens
  - llm_total_output_tokens: Total output tokens
  - llm_total_cached_tokens: Total cached input tokens
  """
  def get_assessment_statistics(course_id, assessment_id) do
    base =
      from(l in LLMUsageLog,
        where: l.course_id == ^course_id and l.assessment_id == ^assessment_id
      )

    total_uses = Repo.aggregate(base, :count)

    unique_submissions =
      Repo.one(
        from(l in base,
          select: count(l.submission_id, :distinct)
        )
      )

    unique_users =
      Repo.one(
        from(l in base,
          select: count(l.user_id, :distinct)
        )
      )

    questions =
      Repo.all(
        from(l in LLMUsageLog,
          join: q in assoc(l, :question),
          where: l.course_id == ^course_id and l.assessment_id == ^assessment_id,
          group_by: [q.id, q.display_order],
          select: %{
            question_id: q.id,
            display_order: q.display_order,
            total_uses: count(l.id),
            unique_submissions: count(l.submission_id, :distinct),
            unique_users: count(l.user_id, :distinct)
          },
          order_by: [asc: q.display_order]
        )
      )

    costs =
      Repo.one(
        from(a in Assessment,
          where: a.id == ^assessment_id and a.course_id == ^course_id,
          select: %{
            llm_total_cost: a.llm_total_cost,
            llm_total_input_tokens: a.llm_total_input_tokens,
            llm_total_output_tokens: a.llm_total_output_tokens,
            llm_total_cached_tokens: a.llm_total_cached_tokens
          }
        )
      ) || %{}

    %{
      total_uses: total_uses,
      unique_submissions: unique_submissions,
      unique_users: unique_users,
      questions: questions,
      llm_total_cost: Map.get(costs, :llm_total_cost) || Decimal.new("0.0"),
      llm_total_input_tokens: Map.get(costs, :llm_total_input_tokens) || 0,
      llm_total_output_tokens: Map.get(costs, :llm_total_output_tokens) || 0,
      llm_total_cached_tokens: Map.get(costs, :llm_total_cached_tokens) || 0
    }
  end

  def get_course_statistics(course_id) do
    assessments_with_stats =
      fetch_llm_course_assessments(course_id)
      |> Enum.map(&build_course_assessment_stats(course_id, &1))

    %{
      course_total_input_tokens: sum_assessment_input_tokens(assessments_with_stats),
      course_total_output_tokens: sum_assessment_output_tokens(assessments_with_stats),
      course_total_cost: sum_assessment_costs(assessments_with_stats),
      assessments: assessments_with_stats
    }
  end

  defp fetch_llm_course_assessments(course_id) do
    Repo.all(
      from(a in Assessment,
        where: a.course_id == ^course_id and a.is_published == true,
        where:
          fragment("? IS NOT NULL AND ? != ''", a.llm_assessment_prompt, a.llm_assessment_prompt) or
            fragment(
              "EXISTS (SELECT 1 FROM questions q WHERE q.assessment_id = ? AND q.question ->> 'llm_prompt' IS NOT NULL AND q.question ->> 'llm_prompt' != '')",
              a.id
            ),
        join: c in assoc(a, :config),
        select: %{
          assessment_id: a.id,
          title: a.title,
          category: c.type,
          llm_total_input_tokens: coalesce(a.llm_total_input_tokens, 0),
          llm_total_output_tokens: coalesce(a.llm_total_output_tokens, 0),
          llm_total_cost: coalesce(a.llm_total_cost, type(^Decimal.new("0.0"), :decimal))
        }
      )
    )
  end

  defp build_course_assessment_stats(course_id, assessment) do
    total_uses = get_assessment_total_uses(course_id, assessment.assessment_id)

    %{
      assessment_id: assessment.assessment_id,
      title: assessment.title,
      category: assessment.category,
      total_uses: total_uses,
      avg_rating: get_assessment_avg_rating(course_id, assessment.assessment_id),
      llm_total_input_tokens: assessment.llm_total_input_tokens,
      llm_total_output_tokens: assessment.llm_total_output_tokens,
      llm_total_cost: assessment.llm_total_cost,
      questions: get_question_stats(course_id, assessment, total_uses)
    }
  end

  defp get_assessment_total_uses(course_id, assessment_id) do
    Repo.one(
      from(l in LLMUsageLog,
        where: l.course_id == ^course_id and l.assessment_id == ^assessment_id,
        select: count(l.id)
      )
    ) || 0
  end

  defp get_assessment_avg_rating(course_id, assessment_id) do
    Repo.one(
      from(f in LLMFeedback,
        where: f.course_id == ^course_id and f.assessment_id == ^assessment_id,
        where: not is_nil(f.rating),
        select: avg(f.rating)
      )
    )
    |> normalize_avg_rating()
  end

  defp get_llm_questions(assessment_id) do
    Repo.all(
      from(q in Question,
        where: q.assessment_id == ^assessment_id,
        where:
          fragment(
            "? ->> 'llm_prompt' IS NOT NULL AND ? ->> 'llm_prompt' != ''",
            q.question,
            q.question
          ),
        order_by: [asc: q.display_order],
        select: %{question_id: q.id, display_order: q.display_order}
      )
    )
  end

  defp get_question_stats(course_id, assessment, total_uses) do
    get_llm_questions(assessment.assessment_id)
    |> Enum.map(&build_question_stats(course_id, assessment, total_uses, &1))
  end

  defp build_question_stats(course_id, assessment, total_uses, question) do
    question_uses =
      get_question_total_uses(course_id, assessment.assessment_id, question.question_id)

    %{
      question_id: question.question_id,
      display_order: question.display_order,
      total_uses: question_uses,
      avg_rating:
        get_question_avg_rating(course_id, assessment.assessment_id, question.question_id),
      llm_total_input_tokens:
        proportional_token_count(assessment.llm_total_input_tokens, question_uses, total_uses),
      llm_total_output_tokens:
        proportional_token_count(assessment.llm_total_output_tokens, question_uses, total_uses),
      llm_total_cost: proportional_cost(assessment.llm_total_cost, question_uses, total_uses)
    }
  end

  defp get_question_total_uses(course_id, assessment_id, question_id) do
    Repo.one(
      from(l in LLMUsageLog,
        where:
          l.course_id == ^course_id and l.assessment_id == ^assessment_id and
            l.question_id == ^question_id,
        select: count(l.id)
      )
    ) || 0
  end

  defp get_question_avg_rating(course_id, assessment_id, question_id) do
    Repo.one(
      from(f in LLMFeedback,
        where:
          f.course_id == ^course_id and f.assessment_id == ^assessment_id and
            f.question_id == ^question_id,
        where: not is_nil(f.rating),
        select: avg(f.rating)
      )
    )
    |> normalize_avg_rating()
  end

  defp normalize_avg_rating(nil), do: nil
  defp normalize_avg_rating(avg_rating), do: Float.round(Decimal.to_float(avg_rating), 2)

  defp proportional_token_count(_total_tokens, _question_uses, 0), do: 0

  defp proportional_token_count(total_tokens, question_uses, total_uses) do
    round(total_tokens * question_uses / total_uses)
  end

  defp proportional_cost(_total_cost, _question_uses, 0), do: Decimal.new("0.0")

  defp proportional_cost(total_cost, question_uses, total_uses) do
    cost_fraction = Decimal.div(Decimal.new(question_uses), Decimal.new(total_uses))
    Decimal.round(Decimal.mult(total_cost, cost_fraction), 6, :half_up)
  end

  defp sum_assessment_input_tokens(assessments_with_stats) do
    Enum.reduce(assessments_with_stats, 0, fn assessment, acc ->
      acc + assessment.llm_total_input_tokens
    end)
  end

  defp sum_assessment_output_tokens(assessments_with_stats) do
    Enum.reduce(assessments_with_stats, 0, fn assessment, acc ->
      acc + assessment.llm_total_output_tokens
    end)
  end

  defp sum_assessment_costs(assessments_with_stats) do
    Enum.reduce(assessments_with_stats, Decimal.new("0.0"), fn assessment, acc ->
      Decimal.add(acc, assessment.llm_total_cost)
    end)
  end

  # =====================
  # Question-level Statistics
  # =====================

  @doc """
  Returns LLM usage statistics for a specific question within an assessment.
  """
  def get_question_statistics(course_id, assessment_id, question_id) do
    base =
      from(l in LLMUsageLog,
        where:
          l.course_id == ^course_id and l.assessment_id == ^assessment_id and
            l.question_id == ^question_id
      )

    total_uses = Repo.aggregate(base, :count)

    unique_submissions =
      Repo.one(
        from(l in base,
          select: count(l.submission_id, :distinct)
        )
      )

    unique_users =
      Repo.one(
        from(l in base,
          select: count(l.user_id, :distinct)
        )
      )

    %{
      total_uses: total_uses,
      unique_submissions: unique_submissions,
      unique_users: unique_users
    }
  end

  # =====================
  # Feedback
  # =====================

  @doc """
  Submits user feedback for the LLM feature.
  """
  def submit_feedback(attrs) do
    %LLMFeedback{}
    |> LLMFeedback.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets feedback for an assessment, optionally filtered by question_id.
  """
  def get_feedback(course_id, assessment_id, question_id \\ nil) do
    query =
      from(f in LLMFeedback,
        join: u in assoc(f, :user),
        where: f.course_id == ^course_id and f.assessment_id == ^assessment_id,
        order_by: [desc: f.inserted_at],
        select: %{
          id: f.id,
          rating: f.rating,
          body: f.body,
          user_name: u.name,
          question_id: f.question_id,
          inserted_at: f.inserted_at
        }
      )

    query =
      if question_id do
        from(f in query, where: f.question_id == ^question_id)
      else
        query
      end

    Repo.all(query)
  end
end
