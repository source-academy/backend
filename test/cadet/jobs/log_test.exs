defmodule Cadet.Jobs.LogEntryTest do
  use Cadet.DataCase

  alias Cadet.Jobs.{Log, LogEntry}

  @name "test_job"

  test "returns true (job runs) when no log entry" do
    assert Log.log_execution(@name, 24 * 60 * 60)

    entry = LogEntry |> where(name: @name) |> Repo.one()

    assert DateTime.compare(entry.last_run, DateTime.utc_now() |> DateTime.add(-1, :minute)) ==
             :gt
  end

  test "returns true (job runs) when log entry old enough" do
    %LogEntry{
      name: @name,
      last_run:
        DateTime.utc_now()
        |> DateTime.add(-25, :hour)
        |> DateTime.truncate(:second)
    }
    |> Repo.insert!()

    assert Log.log_execution(@name, 24 * 60 * 60)

    entry = LogEntry |> where(name: @name) |> Repo.one()

    assert DateTime.compare(entry.last_run, DateTime.utc_now() |> DateTime.add(-1, :minute)) ==
             :gt
  end

  test "returns false (job does not run) when log entry too recent" do
    %LogEntry{
      name: @name,
      last_run:
        DateTime.utc_now()
        |> DateTime.add(-23, :hour)
        |> DateTime.truncate(:second)
    }
    |> Repo.insert!()

    refute Log.log_execution(@name, 24 * 60 * 60)
  end
end
