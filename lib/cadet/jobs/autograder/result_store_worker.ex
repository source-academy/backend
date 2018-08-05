defmodule Cadet.Autograder.ResultStoreWorker do
  @moduledoc """
  This module writes results from the autograder to db. Separate worker is created with lower
  concurrency on the assumption  that autograding time >> db IO time so as to reduce db load.
  """
  use Que.Worker, concurrency: 5

  require Logger

  alias Ecto.Multi

  alias Cadet.Repo
  alias Cadet.Assessments.Answer

  def perform(%{answer_id: answer_id, result: result}) do
    Multi.new()
    |> Multi.run(:fetch, fn _ -> fetch_answer(answer_id) end)
    |> Multi.run(:update, fn %{fetch: answer} -> update_answer(answer, result) end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        nil

      {:error, failed_operation, failed_value, _} ->
        Logger.error(
          "Failed to store autograder result. " <>
            "answer_id: #{answer_id}, #{failed_operation}, #{inspect(failed_value)}"
        )
    end
  end

  defp fetch_answer(answer_id) do
    answer = Repo.get(Answer, answer_id)

    if answer do
      {:ok, answer}
    else
      {:error, "Answer not found"}
    end
  end

  defp update_answer(answer = %Answer{}, result = %{status: status}) do
    changes =
      case status do
        :success -> %{grade: result.grade, autograding_status: :success}
        :failed -> %{autograding_status: :failed}
      end

    answer
    |> Answer.autograding_changeset(changes)
    |> Repo.update()
  end
end
