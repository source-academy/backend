defmodule Cadet.Autograder.ResultStoreWorker do
  @moduledoc """
  This module writes results from the autograder to db. Separate worker is created with lower
  concurrency on the assumption  that autograding time >> db IO time so as to reduce db load.
  """
  use Que.Worker, concurrency: 5

  alias Cadet.Repo
  alias Cadet.Assessments.Answer

  def perform(%{answer_id: answer_id, result: result}) do
    %Answer{}
    |> Answer.autograder_changeset(%{grade: result})
    |> Repo.update()
  end
end
