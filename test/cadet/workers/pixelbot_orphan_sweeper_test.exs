defmodule Cadet.Workers.PixelbotOrphanSweeperTest do
  use Cadet.DataCase

  import ExUnit.CaptureLog
  import Mock

  alias Cadet.Workers.PixelbotOrphanSweeper

  @moduletag :serial

  test "perform/1 deletes orphan keys in batches of at most 1,000" do
    parent = self()
    old_timestamp = DateTime.utc_now() |> DateTime.add(-2, :day) |> DateTime.to_iso8601()

    objects =
      for index <- 1..2_001 do
        %{key: "course-1/orphan-#{index}.pdf", last_modified: old_timestamp}
      end

    with_mocks [
      {ExAws, [:passthrough],
       stream!: fn _operation, _options -> objects end,
       request: fn _operation, _options -> {:ok, %{}} end},
      {ExAws.S3, [:passthrough],
       delete_multiple_objects: fn _bucket, keys ->
         send(parent, {:deleted_batch, length(keys)})
         :delete_operation
       end}
    ] do
      capture_log(fn -> assert :ok = PixelbotOrphanSweeper.perform(%Oban.Job{}) end)
    end

    assert_receive {:deleted_batch, 1_000}
    assert_receive {:deleted_batch, 1_000}
    assert_receive {:deleted_batch, 1}
    refute_receive {:deleted_batch, _}
  end
end
