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

    %{
      total_uses: total_uses,
      unique_submissions: unique_submissions,
      unique_users: unique_users,
      questions: questions
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
