defmodule Cadet.LLMStats do
  @moduledoc """
  Context module for LLM usage statistics and feedback.
  Provides per-assessment and per-question statistics and feedback management.
  """

  import Ecto.Query
  alias Cadet.Repo
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

    # Per-question breakdown
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

    # ADDED: Fetch the cost and token data from the Assessment table
    costs =
      Repo.one(
        from(a in Cadet.Assessments.Assessment,
          where: a.id == ^assessment_id and a.course_id == ^course_id,
          select: %{
            llm_total_cost: a.llm_total_cost,
            llm_total_input_tokens: a.llm_total_input_tokens,
            llm_total_output_tokens: a.llm_total_output_tokens,
            llm_total_cached_tokens: a.llm_total_cached_tokens
          }
        )
      ) || %{}

    # Merge the costs into the final map that gets sent to React
    %{
      total_uses: total_uses,
      unique_submissions: unique_submissions,
      unique_users: unique_users,
      questions: questions,
      # Add the cost data (with safe fallbacks if nil)
      llm_total_cost: Map.get(costs, :llm_total_cost) || Decimal.new("0.0"),
      llm_total_input_tokens: Map.get(costs, :llm_total_input_tokens) || 0,
      llm_total_output_tokens: Map.get(costs, :llm_total_output_tokens) || 0,
      llm_total_cached_tokens: Map.get(costs, :llm_total_cached_tokens) || 0
    }
  end

  def get_course_statistics(course_id) do
    assessments =
      from(a in Cadet.Assessments.Assessment,
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
          llm_total_cost: coalesce(a.llm_total_cost, 0)
        }
      )
      |> Repo.all()

    assessments_with_stats =
      Enum.map(assessments, fn assessment ->
        total_uses =
          Repo.one(
            from(l in LLMUsageLog,
              where: l.course_id == ^course_id and l.assessment_id == ^assessment.assessment_id,
              select: count(l.id)
            )
          ) || 0

        avg_rating =
          Repo.one(
            from(f in LLMFeedback,
              where:
                f.course_id == ^course_id and f.assessment_id == ^assessment.assessment_id and
                  not is_nil(f.rating),
              select: avg(f.rating)
            )
          )

        avg_rating =
          if is_nil(avg_rating) do
            nil
          else
            avg_rating |> Decimal.to_float() |> Float.round(2)
          end

        questions =
          Repo.all(
            from(q in Cadet.Assessments.Question,
              where: q.assessment_id == ^assessment.assessment_id,
              where:
                fragment(
                  "? ->> 'llm_prompt' IS NOT NULL AND ? ->> 'llm_prompt' != ''",
                  q.question,
                  q.question
                ),
              order_by: [asc: q.display_order],
              select: %{
                question_id: q.id,
                display_order: q.display_order
              }
            )
          )

        question_stats =
          Enum.map(questions, fn question ->
            question_uses =
              Repo.one(
                from(l in LLMUsageLog,
                  where:
                    l.course_id == ^course_id and l.assessment_id == ^assessment.assessment_id and
                      l.question_id == ^question.question_id,
                  select: count(l.id)
                )
              ) || 0

            question_rating =
              Repo.one(
                from(f in LLMFeedback,
                  where:
                    f.course_id == ^course_id and f.assessment_id == ^assessment.assessment_id and
                      f.question_id == ^question.question_id and not is_nil(f.rating),
                  select: avg(f.rating)
                )
              )

            question_rating =
              if is_nil(question_rating) do
                nil
              else
                question_rating |> Decimal.to_float() |> Float.round(2)
              end

            question_input_tokens =
              if total_uses > 0 do
                round(assessment.llm_total_input_tokens * question_uses / total_uses)
              else
                0
              end

            question_output_tokens =
              if total_uses > 0 do
                round(assessment.llm_total_output_tokens * question_uses / total_uses)
              else
                0
              end

            question_cost =
              if total_uses > 0 do
                Decimal.mult(
                  assessment.llm_total_cost,
                  Decimal.div(Decimal.new(question_uses), Decimal.new(total_uses))
                )
                |> Decimal.round(6, :half_up)
              else
                Decimal.new("0.0")
              end

            %{
              question_id: question.question_id,
              display_order: question.display_order,
              total_uses: question_uses,
              avg_rating: question_rating,
              llm_total_input_tokens: question_input_tokens,
              llm_total_output_tokens: question_output_tokens,
              llm_total_cost: question_cost
            }
          end)

        %{
          assessment_id: assessment.assessment_id,
          title: assessment.title,
          category: assessment.category,
          total_uses: total_uses,
          avg_rating: avg_rating,
          llm_total_input_tokens: assessment.llm_total_input_tokens,
          llm_total_output_tokens: assessment.llm_total_output_tokens,
          llm_total_cost: assessment.llm_total_cost,
          questions: question_stats
        }
      end)

    course_total_input_tokens =
      Enum.reduce(assessments_with_stats, 0, fn assessment, acc ->
        acc + assessment.llm_total_input_tokens
      end)

    course_total_output_tokens =
      Enum.reduce(assessments_with_stats, 0, fn assessment, acc ->
        acc + assessment.llm_total_output_tokens
      end)

    course_total_cost =
      Enum.reduce(assessments_with_stats, Decimal.new("0.0"), fn assessment, acc ->
        Decimal.add(acc, assessment.llm_total_cost)
      end)

    %{
      course_total_input_tokens: course_total_input_tokens,
      course_total_output_tokens: course_total_output_tokens,
      course_total_cost: course_total_cost,
      assessments: assessments_with_stats
    }
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
