defmodule Cadet.Autograder.ResultStoreWorker do
  @moduledoc """
  This module writes results from the autograder to db. Separate worker is created with lower
  concurrency on the assumption that autograding time >> db IO time so as to reduce db load.
  """
  use Oban.Worker,
    queue: :autograder,
    max_attempts: 1

  require Logger

  import Cadet.SharedHelper
  import Ecto.Query

  alias Ecto.Multi

  alias Cadet.{Assessments, Repo}
  alias Cadet.Assessments.{Answer, Assessment, Submission}
  alias Cadet.Courses.AssessmentConfig

  @doc """
  Oban entry point.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: args}), do: run(args)

  # Backwards-compatible direct entry: tests and other call-sites pass a
  # plain args map.
  def perform(args) when is_map(args) and not is_struct(args), do: run(args)

  @doc """
  Public entry point used by tests and direct callers (does not require an
  Oban job struct).
  """
  def run(params) when is_map(params) do
    answer_id = get_arg(params, :answer_id)
    result = normalize_result(get_arg(params, :result))

    do_run(answer_id, result, get_arg(params, :overwrite, false))
  end

  # Suppress the Ecto.Multi opaqueness false positive (call_without_opaque) from
  # the idiomatic `Multi.new() |> Multi.run(...)` pipeline.
  @dialyzer {:nowarn_function, do_run: 3}
  defp do_run(answer_id, result, overwrite) when is_ecto_id(answer_id) do
    Multi.new()
    |> Multi.run(:fetch, fn _repo, _ -> fetch_answer(answer_id) end)
    |> Multi.run(:update, fn _repo, %{fetch: answer} ->
      update_answer(answer, result, overwrite)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        :ok

      {:error, failed_operation, failed_value, _} ->
        error_message =
          "Failed to store autograder result. " <>
            "answer_id: #{answer_id}, #{failed_operation}, #{inspect(failed_value, pretty: true)}"

        Logger.error(error_message)
        Sentry.capture_message(error_message)
        {:error, error_message}
    end
  end

  defp normalize_result(result) when is_map(result) do
    %{
      score: get_arg(result, :score),
      max_score: get_arg(result, :max_score),
      status: normalize_status(get_arg(result, :status)),
      result: get_arg(result, :result)
    }
  end

  defp normalize_status("success"), do: :success
  defp normalize_status("failed"), do: :failed
  defp normalize_status(status) when is_atom(status), do: status

  defp get_arg(args, key, default \\ nil) do
    Map.get(args, key, Map.get(args, Atom.to_string(key), default))
  end

  defp fetch_answer(answer_id) when is_ecto_id(answer_id) do
    answer =
      Answer
      |> join(:inner, [a], q in assoc(a, :question))
      |> preload([_, q], question: q)
      |> Repo.get(answer_id)

    if answer do
      {:ok, answer}
    else
      {:error, "Answer not found"}
    end
  end

  defp update_answer(
         answer = %Answer{submission_id: submission_id},
         result = %{status: status},
         overwrite
       ) do
    xp =
      cond do
        result.max_score == 0 and length(result.result) > 0 ->
          testcase_results = result.result

          num_passed =
            testcase_results |> Enum.filter(fn r -> r["resultType"] == "pass" end) |> length()

          Integer.floor_div(answer.question.max_xp * num_passed, length(testcase_results))

        result.max_score == 0 ->
          0

        true ->
          Integer.floor_div(answer.question.max_xp * result.score, result.max_score)
      end

    changes = %{
      xp: xp,
      autograding_status: status,
      autograding_results: result.result
    }

    changes = if(overwrite, do: Map.put(changes, :xp_adjustment, 0), else: changes)

    res =
      answer
      |> Answer.autograding_changeset(changes)
      |> Repo.update()

    submission = Repo.get(Submission, submission_id)
    assessment = Repo.get(Assessment, submission.assessment_id)
    assessment_config = Repo.get_by(AssessmentConfig, id: assessment.config_id)
    is_grading_auto_published = assessment_config.is_grading_auto_published
    is_manually_graded = assessment_config.is_manually_graded

    if Assessments.is_fully_autograded?(submission_id) and is_grading_auto_published and
         not is_manually_graded do
      Assessments.publish_grading(submission_id)
    end

    res
  end
end
