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
  def course_stats(conn, %{"course_id" => course_id}) do
    case parse_id(course_id) do
      {:ok, course_id} ->
        stats = LLMStats.get_course_statistics(course_id)
        json(conn, stats)

      :error ->
        conn |> put_status(:bad_request) |> text("Invalid course_id")
    end
  end

  def assessment_stats(conn, %{"course_id" => course_id, "assessment_id" => assessment_id}) do
    with {:ok, course_id} <- parse_id(course_id),
         {:ok, assessment_id} <- parse_id(assessment_id) do
      stats = LLMStats.get_assessment_statistics(course_id, assessment_id)
      json(conn, stats)
    else
      :error -> conn |> put_status(:bad_request) |> text("Invalid course_id or assessment_id")
    end
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
    with {:ok, course_id} <- parse_id(course_id),
         {:ok, assessment_id} <- parse_id(assessment_id),
         {:ok, question_id} <- parse_id(question_id) do
      stats = LLMStats.get_question_statistics(course_id, assessment_id, question_id)
      json(conn, stats)
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid course_id, assessment_id, or question_id")
    end
  end

  @doc """
  GET /admin/llm-stats/:assessment_id/feedback
  Returns feedback for an assessment, optionally filtered by question_id query param.
  """
  def get_feedback(conn, params = %{"course_id" => course_id, "assessment_id" => assessment_id}) do
    with {:ok, course_id} <- parse_id(course_id),
         {:ok, assessment_id} <- parse_id(assessment_id),
         {:ok, question_id} <- parse_optional_id(Map.get(params, "question_id")) do
      feedback = LLMStats.get_feedback(course_id, assessment_id, question_id)
      json(conn, feedback)
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid course_id, assessment_id, or question_id")
    end
  end

  @doc """
  POST /admin/llm-stats/:assessment_id/feedback
  Submits new feedback for the LLM feature on an assessment (optionally for a specific question).
  """
  def submit_feedback(
        conn,
        params = %{"course_id" => course_id, "assessment_id" => assessment_id}
      ) do
    with {:ok, course_id} <- parse_id(course_id),
         {:ok, assessment_id} <- parse_id(assessment_id),
         {:ok, question_id} <- parse_optional_id(Map.get(params, "question_id")) do
      user = conn.assigns[:current_user]

      attrs = %{
        course_id: course_id,
        user_id: user.id,
        assessment_id: assessment_id,
        question_id: question_id,
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
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid course_id, assessment_id, or question_id")
    end
  end

  defp parse_id(id) when is_integer(id), do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {parsed, ""} -> {:ok, parsed}
      _ -> :error
    end
  end

  defp parse_optional_id(nil), do: {:ok, nil}
  defp parse_optional_id(id), do: parse_id(id)
end
