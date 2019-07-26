defmodule Cadet.Autograder.ResultStoreWorker do
  @moduledoc """
  This module writes results from the autograder to db. Separate worker is created with lower
  concurrency on the assumption that autograding time >> db IO time so as to reduce db load.
  """
  use Que.Worker, concurrency: 5

  require Logger

  import Cadet.SharedHelper
  import Ecto.Query

  alias Ecto.Multi

  alias Cadet.Repo
  alias Cadet.Assessments.Answer

  def perform(%{answer_id: answer_id, result: result}) when is_ecto_id(answer_id) do
    Multi.new()
    |> Multi.run(:fetch, fn _repo, _ -> fetch_answer(answer_id) end)
    |> Multi.run(:update, fn _repo, %{fetch: answer} -> update_answer(answer, result) end)
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

  defp update_answer(answer = %Answer{}, result = %{status: status}) do
    xp =
      if answer.question.max_grade == 0 do
        0
      else
        Integer.floor_div(answer.question.max_xp * result.grade, answer.question.max_grade)
      end

    new_adjustment =
      if answer.grader_id do
        answer.adjustment - result.grade
      else
        0
      end

    changes = %{
      adjustment: new_adjustment,
      grade: result.grade,
      xp: xp,
      autograding_status: status,
      autograding_results: result.result
    }

    answer
    |> Answer.autograding_changeset(changes)
    |> Repo.update()
  end
end
