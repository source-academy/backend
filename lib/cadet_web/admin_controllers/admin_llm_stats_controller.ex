defmodule CadetWeb.AdminLLMStatsController do
  @moduledoc """
  Controller for per-assessment and per-question LLM usage statistics and feedback.
  """

  use CadetWeb, :controller
  require Logger

  alias Cadet.LLMStats

  @doc """
  GET /admin/llm-stats/:assessment_id
  Returns assessment-level LLM usage statistics with per-question breakdown.
  """
  def assessment_stats(conn, %{"course_id" => course_id, "assessment_id" => assessment_id}) do
    stats = LLMStats.get_assessment_statistics(course_id, assessment_id)
    json(conn, stats)
  end

  @doc """
  GET /admin/llm-stats/:assessment_id/:question_id
  Returns question-level LLM usage statistics.
  """
  def question_stats(conn, %{
        "course_id" => course_id,
        "assessment_id" => assessment_id,
        "question_id" => question_id
      }) do
    stats = LLMStats.get_question_statistics(course_id, assessment_id, question_id)
    json(conn, stats)
  end

  @doc """
  GET /admin/llm-stats/:assessment_id/feedback
  Returns feedback for an assessment, optionally filtered by question_id query param.
  """
  def get_feedback(conn, params = %{"course_id" => course_id, "assessment_id" => assessment_id}) do
    question_id = Map.get(params, "question_id")
    feedback = LLMStats.get_feedback(course_id, assessment_id, question_id)
    json(conn, feedback)
  end

  @doc """
  POST /admin/llm-stats/:assessment_id/feedback
  Submits new feedback for the LLM feature on an assessment (optionally for a specific question).
  """
  def submit_feedback(
        conn,
        params = %{"course_id" => course_id, "assessment_id" => assessment_id}
      ) do
    user = conn.assigns[:current_user]

    attrs = %{
      course_id: course_id,
      user_id: user.id,
      assessment_id: assessment_id,
      question_id: Map.get(params, "question_id"),
      rating: Map.get(params, "rating"),
      body: Map.get(params, "body")
    }

    case LLMStats.submit_feedback(attrs) do
      {:ok, _feedback} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Feedback submitted successfully"})

      {:error, changeset} ->
        Logger.error("Failed to submit LLM feedback: #{inspect(changeset.errors)}")

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Failed to submit feedback"})
    end
  end
end
