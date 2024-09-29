defmodule Cadet.Autograder.ResultStoreWorker do
  # Suppress no_match from macro
  @dialyzer {:no_match, __after_compile__: 2}
  @moduledoc """
  This module writes results from the autograder to db. Separate worker is created with lower
  concurrency on the assumption that autograding time >> db IO time so as to reduce db load.
  """
  use Que.Worker, concurrency: 5

  require Logger

  import Cadet.SharedHelper
  import Ecto.Query

  alias Ecto.Multi

  alias Cadet.{Assessments, Repo}
  alias Cadet.Assessments.{Answer, Assessment, Submission}
  alias Cadet.Courses.AssessmentConfig

  def perform(params = %{answer_id: answer_id, result: result})
      when is_ecto_id(answer_id) do
    Multi.new()
    |> Multi.run(:fetch, fn _repo, _ -> fetch_answer(answer_id) end)
    |> Multi.run(:update, fn _repo, %{fetch: answer} ->
      update_answer(answer, result, params[:overwrite] || false)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        nil

      {:error, failed_operation, failed_value, _} ->
        error_message =
          "Failed to store autograder result. " <>
            "answer_id: #{answer_id}, #{failed_operation}, #{inspect(failed_value, pretty: true)}"

        Logger.error(error_message)
        Sentry.capture_message(error_message)
    end
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
