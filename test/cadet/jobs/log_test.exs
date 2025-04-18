defmodule Cadet.Jobs.LogEntryTest do
  use Cadet.DataCase

  alias Cadet.Jobs.{Log, LogEntry}
  alias Timex.Duration

  @name "test_job"

  test "returns true (job runs) when no log entry" do
    assert Log.log_execution(@name, Duration.from_days(1))

    entry = LogEntry |> where(name: @name) |> Repo.one()

    assert Timex.compare(
             entry.last_run,
             Timex.subtract(Timex.now(), Duration.from_minutes(1))
           ) == 1
  end

  test "returns true (job runs) when log entry old enough" do
    %LogEntry{
      name: @name,
      last_run:
        Timex.now()
        |> Timex.subtract(Duration.from_hours(25))
        |> DateTime.truncate(:second)
    }
    |> Repo.insert!()

    assert Log.log_execution(@name, Duration.from_days(1))

    entry = LogEntry |> where(name: @name) |> Repo.one()

    assert Timex.compare(
             entry.last_run,
             Timex.subtract(Timex.now(), Duration.from_minutes(1))
           ) == 1
  end

  test "returns false (job does not run) when log entry too recent" do
    %LogEntry{
      name: @name,
      last_run:
        Timex.now()
        |> Timex.subtract(Duration.from_hours(23))
        |> DateTime.truncate(:second)
    }
    |> Repo.insert!()

    refute Log.log_execution(@name, Duration.from_days(1))
  end
end
