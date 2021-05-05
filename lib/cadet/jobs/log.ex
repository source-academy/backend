defmodule Cadet.Jobs.LogEntry do
  @moduledoc """
  A job log entry.
  """
  use Cadet, :model

  schema "job_log" do
    field(:name, :string)
    field(:last_run, :utc_datetime)
  end
end

defmodule Cadet.Jobs.Log do
  @moduledoc """
  Logs job executions.
  """
  use Cadet, :context

  import Ecto.Query

  alias Cadet.Jobs.LogEntry

  def log_execution(name, %Timex.Duration{} = period) when is_binary(name) do
    result =
      Repo.transaction(fn ->
        entry =
          LogEntry
          |> where(name: ^name)
          |> lock("FOR UPDATE")
          |> Repo.one()

        now = DateTime.truncate(Timex.now(), :second)

        cond do
          # no log entry, try to insert and then return true (run the job)
          # if someone else races and inserts first, unique key on name will cause us to raise
          is_nil(entry) ->
            %LogEntry{name: name, last_run: now}
            |> Repo.insert!()

            true

          # existing log entry and the last_run is far enough in the past
          # we have the lock, update and return true (run the job)
          now |> Timex.subtract(period) |> Timex.compare(entry.last_run) >= 0 ->
            entry
            |> change(last_run: now)
            |> Repo.update!()

            true

          # existing log entry but the last_run is too recent
          # don't run the job
          true ->
            false
        end
      end)

    case result do
      {:ok, should_run} -> should_run
      _ -> false
    end
  end
end
