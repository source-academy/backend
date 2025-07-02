defmodule Cadet.Logger.CloudWatchLogger do
  @moduledoc """
  A custom Logger backend that sends logs to AWS CloudWatch.
  This backend can be configured to log at different levels and formats,
  and can include specific metadata in the logs.
  """

  @behaviour :gen_event
  require Logger

  defstruct [:level, :format, :metadata, :log_group, :log_stream, :buffer, :timer_ref]

  @max_buffer_size 1000
  @max_retries 3
  @retry_delay 500
  @flush_interval 5000

  @impl true
  def init({__MODULE__, opts}) when is_list(opts) do
    config = configure_merge(read_env(), opts)
    {:ok, init(config, %__MODULE__{})}
  end

  @impl true
  def init({__MODULE__, name}) when is_atom(name) do
    config = read_env()
    {:ok, init(config, %__MODULE__{})}
  end

  @impl true
  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  @impl true
  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    %{
      format: format,
      metadata: metadata,
      buffer: buffer,
      log_stream: log_stream,
      log_group: log_group
    } = state

    if meet_level?(level, state.level) and not meet_cloudwatch_error?(msg) do
      formatted_msg = Logger.Formatter.format(format, level, msg, ts, take_metadata(md, metadata))
      timestamp = timestamp_from_logger_ts(ts)

      log_event = %{
        "timestamp" => timestamp,
        "message" => IO.chardata_to_string(formatted_msg)
      }

      new_buffer = [log_event | buffer]

      new_buffer =
        if length(new_buffer) >= @max_buffer_size do
          flush_buffer_async(log_stream, log_group, new_buffer)
          []
        else
          new_buffer
        end

      {:ok, %{state | buffer: new_buffer}}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_info(:flush_buffer, state) do
    %{buffer: buffer, timer_ref: timer_ref, log_stream: log_stream, log_group: log_group} = state

    if timer_ref, do: Process.cancel_timer(timer_ref)

    new_state =
      if length(buffer) > 0 do
        flush_buffer_sync(log_stream, log_group, buffer)
        %{state | buffer: []}
      else
        state
      end

    new_timer_ref = schedule_flush(@flush_interval)
    {:ok, %{new_state | timer_ref: new_timer_ref}}
  end

  @impl true
  def terminate(_reason, state) do
    %{log_stream: log_stream, log_group: log_group, buffer: buffer, timer_ref: timer_ref} = state

    if timer_ref, do: Process.cancel_timer(timer_ref)
    flush_buffer_sync(log_stream, log_group, buffer)
    :ok
  end

  def handle_event(_, state), do: {:ok, state}
  def handle_call(_, state), do: {:ok, :ok, state}
  def handle_info(_, state), do: {:ok, state}

  # Helpers
  defp configure(options, state) do
    config = configure_merge(read_env(), options)
    Application.put_env(:logger, __MODULE__, config)
    init(config, state)
  end

  defp meet_level?(_lvl, nil), do: true

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp meet_cloudwatch_error?(msg) when is_binary(msg) do
    String.starts_with?(msg, "Failed to send log to CloudWatch")
  end

  defp meet_cloudwatch_error?(_) do
    false
  end

  defp flush_buffer_async(log_stream, log_group, buffer) do
    if length(buffer) > 0 do
      Task.start(fn -> send_to_cloudwatch(log_stream, log_group, buffer) end)
    end
  end

  defp flush_buffer_sync(log_stream, log_group, buffer) do
    if length(buffer) > 0 do
      send_to_cloudwatch(log_stream, log_group, buffer)
    end
  end

  defp schedule_flush(interval) do
    Process.send_after(self(), :flush_buffer, interval)
  end

  defp send_to_cloudwatch(log_stream, log_group, buffer) do
    # Ensure that the already have ExAws authentication configured
    with :ok <- check_exaws_config() do
      operation = build_log_operation(log_stream, log_group, buffer)

      operation
      |> send_with_retry()
    end
  end

  defp build_log_operation(log_stream, log_group, buffer) do
    # The headers and body structure can be found in the AWS API documentation:
    # https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
    %ExAws.Operation.JSON{
      http_method: :post,
      service: :logs,
      headers: [
        {"x-amz-target", "Logs_20140328.PutLogEvents"},
        {"content-type", "application/x-amz-json-1.1"}
      ],
      data: %{
        "logGroupName" => log_group,
        "logStreamName" => log_stream,
        "logEvents" => Enum.reverse(buffer)
      }
    }
  end

  defp check_exaws_config do
    id = Application.get_env(:ex_aws, :access_key_id) || System.get_env("AWS_ACCESS_KEY_ID")

    secret =
      Application.get_env(:ex_aws, :secret_access_key) || System.get_env("AWS_SECRET_ACCESS_KEY")

    region = Application.get_env(:ex_aws, :region) || System.get_env("AWS_REGION")

    cond do
      is_nil(id) or id == "" or is_nil(secret) or secret == "" ->
        Logger.error(
          "Failed to send log to CloudWatch. AWS credentials missing. Ensure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set.
        "
        )

        :error

      region in [nil, ""] ->
        Logger.error(
          "Failed to send log to CloudWatch. AWS region not configured. Set AWS_REGION or :region under :ex_aws in config.
        "
        )

        :error

      true ->
        :ok
    end
  end

  defp send_with_retry(operation, retries \\ @max_retries)

  defp send_with_retry(operation, retries) when retries > 0 do
    case ExAws.request(operation) do
      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to send log to CloudWatch: #{inspect(reason)}. Retrying...")
        # Wait before retrying
        :timer.sleep(@retry_delay)
        send_with_retry(operation, retries - 1)
    end
  end

  defp send_with_retry(_, 0) do
    Logger.error("Failed to send log to CloudWatch after multiple retries.")
  end

  defp init(config, state) do
    level = Keyword.get(config, :level)
    format = Logger.Formatter.compile(Keyword.get(config, :format))
    raw_metadata = Keyword.get(config, :metadata, [])
    metadata = configure_metadata(raw_metadata)
    log_group = Keyword.get(config, :log_group, "cadet-logs")
    log_stream = Keyword.get(config, :log_stream, "#{node()}-#{:os.system_time(:second)}")
    timer_ref = schedule_flush(@flush_interval)

    %{
      state
      | level: level,
        format: format,
        metadata: metadata,
        log_group: log_group,
        log_stream: log_stream,
        buffer: [],
        timer_ref: timer_ref
    }
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp take_metadata(metadata, :all) do
    metadata
  end

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
  end

  defp timestamp_from_logger_ts({{year, month, day}, {hour, minute, second, microsecond}}) do
    datetime = %DateTime{
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      microsecond: {microsecond, 6},
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      utc_offset: 0,
      std_offset: 0
    }

    DateTime.to_unix(datetime, :millisecond)
  end

  defp read_env do
    Application.get_env(:logger, __MODULE__, Application.get_env(:logger, :cloudwatch_logger, []))
  end

  """
  Merges the given options with the existing environment configuration.
  If a key exists in both, the value from `options` will take precedence.
  """

  defp configure_merge(env, options) do
    Keyword.merge(env, options, fn
      _, _v1, v2 -> v2
    end)
  end
end
