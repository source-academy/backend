defmodule Cadet.Logger.CloudWatchLoggerTest do
  use ExUnit.Case, async: false
  require Logger
  import Mox
  alias Cadet.Logger.CloudWatchLogger

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    Mox.defmock(ExAwsMock, for: ExAws.Behaviour)
    Application.put_env(:ex_aws, :ex_aws_mock, ExAwsMock)

    Application.put_env(:logger, :cloudwatch_logger,
      level: :info,
      log_group: "test_log_group",
      log_stream: "test_log_stream",
      buffer_size: 10,
      format: "$time $metadata[$level] $message",
      metadata: [:request_id]
    )

    LoggerBackends.add({CloudWatchLogger, :cloudwatch_logger})

    on_exit(fn ->
      LoggerBackends.remove({CloudWatchLogger, :cloudwatch_logger})
    end)

    :ok
  end

  test "flushes buffered events via ExAws" do
    expect(ExAwsMock, :request, fn %ExAws.Operation.JSON{} = op ->
      IO.puts("ExAws request: #{inspect(op)}")
      %{http_method: http_method, data: data, headers: headers, service: service} = op

      assert http_method == :post
      assert service == :logs

      assert headers == [
               {"x-amz-target", "Logs_20140328.PutLogEvents"},
               {"content-type", "application/x-amz-json-1.1"}
             ]

      assert data["logGroupName"] == "test_log_group"
      assert data["logStreamName"] == "test_log_stream"
      assert is_list(data["logEvents"])

      assert Enum.all?(data["logEvents"], fn event ->
               is_map(event) and
                 Map.has_key?(event, "timestamp") and
                 Map.has_key?(event, "message")
             end)

      assert Enum.all?(
               data["logEvents"],
               fn event ->
                 String.contains?(event["message"], "[error] this is an error") or
                   String.contains?(event["message"], "[warn] this is a warning")
               end
             )

      {:ok,
       %{
         status_code: 200
       }}
    end)

    Logger.error("this is an error")
    Logger.warn("this is a warning")

    # wait for async flush
    Process.sleep(5100)
  end
end
