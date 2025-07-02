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
      format: "$time $metadata[$level] $message",
      metadata: [:request_id]
    )

    LoggerBackends.add({CloudWatchLogger, :cloudwatch_logger})

    Logger.configure_backend(:console, level: :error)

    on_exit(fn ->
      LoggerBackends.remove({CloudWatchLogger, :cloudwatch_logger})
      Logger.configure_backend(:console, level: :warning)
    end)

    :ok
  end

  test "flushes buffered events via ExAws" do
    expect(ExAwsMock, :request, fn %ExAws.Operation.JSON{} = op ->
      %{data: data} = op

      assert_config(op)

      assert Enum.all?(data["logEvents"], fn event ->
               is_map(event) and
                 Map.has_key?(event, "timestamp") and
                 Map.has_key?(event, "message")
             end)

      assert Enum.all?(
               data["logEvents"],
               fn event ->
                 is_map(event) and
                   Map.has_key?(event, "message") and
                   (String.contains?(event["message"], "[error] this is an error") or
                      String.contains?(event["message"], "[warning] this is a warning") or
                      String.contains?(event["message"], "[warn] this is a warning"))
               end
             )

      {:ok,
       %{
         status_code: 200
       }}
    end)

    Logger.error("this is an error")
    Logger.warning("this is a warning")

    # wait for timer to flush the buffer
    Process.sleep(5100)
  end

  test "Force flush the buffer when the buffer size is reached" do
    expect(ExAwsMock, :request, fn %ExAws.Operation.JSON{} = op ->
      %{data: data} = op

      assert_config(op)

      assert Enum.all?(data["logEvents"], fn event ->
               is_map(event) and
                 Map.has_key?(event, "timestamp") and
                 Map.has_key?(event, "message")
             end)

      assert Enum.all?(
               data["logEvents"],
               fn event ->
                 is_map(event) and
                   Map.has_key?(event, "message") and
                   (String.contains?(event["message"], "[warning] this is a warning") or
                      String.contains?(event["message"], "[warn] this is a warning"))
               end
             )

      {:ok,
       %{
         status_code: 200
       }}
    end)

    for _ <- 1..1000 do
      Logger.warning("this is a warning")
    end

    # don't wait for timer
    Process.sleep(100)
  end

  test "Failed to send log to CloudWatch" do
    expect(ExAwsMock, :request, 3, fn %ExAws.Operation.JSON{} = op ->
      assert_config(op)

      {:error, "Failed to send log to CloudWatch"}
    end)

    Logger.warning("this is a warning")

    Process.sleep(6000)
  end

  defp assert_config(%{http_method: http_method, data: data, headers: headers, service: service}) do
    assert http_method == :post
    assert service == :logs

    assert headers == [
             {"x-amz-target", "Logs_20140328.PutLogEvents"},
             {"content-type", "application/x-amz-json-1.1"}
           ]

    assert data["logGroupName"] == "test_log_group"
    assert data["logStreamName"] == "test_log_stream"
  end
end
