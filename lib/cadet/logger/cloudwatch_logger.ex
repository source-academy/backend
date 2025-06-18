defmodule Cadet.Logger.CloudWatchLogger do
  @moduledoc """
  A custom Logger backend that sends logs to AWS CloudWatch.
  This backend can be configured to log at different levels and formats,
  and can include specific metadata in the logs.
  """

  @behaviour :gen_event
  require Logger

  defstruct [:level, :format, :metadata, :log_group, :log_stream]

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
    %{format: format, metadata: metadata} = state

    if meet_level?(level, state.level) do
      formatted_msg = Logger.Formatter.format(format, level, msg, ts, take_metadata(md, metadata))
      spawn(fn -> send_to_cloudwatch(formatted_msg, state) end)
    end

    {:ok, state}
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

  defp send_to_cloudwatch(msg, state) do
    %{log_group: log_group, log_stream: log_stream} = state

    # Ensure that the already have ExAws authentication configured
    if :ets.whereis(ExAws.Config.AuthCache) != :undefined do
      # The headers and body structure can be found in the AWS API documentation:
      # https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
      operation = %ExAws.Operation.JSON{
        http_method: :post,
        service: :logs,
        headers: [
          {"x-amz-target", "Logs_20140328.PutLogEvents"},
          {"content-type", "application/x-amz-json-1.1"}
        ],
        data: %{
          "logGroupName" => log_group,
          "logStreamName" => log_stream,
          "logEvents" => [
            %{
              "timestamp" => :os.system_time(:millisecond),
              "message" => msg
            }
          ]
        }
      }

      operation
      |> ExAws.request()
      |> case do
        {:ok, _response} ->
          :ok

        {:error, reason} ->
          Logger.error("Failed to send log to CloudWatch: #{inspect(reason)}")
      end
    else
      Logger.error("ExAws.Config.AuthCache is not available. Cannot send logs to CloudWatch.")
    end
  end

  defp init(config, state) do
    level = Keyword.get(config, :level)
    format = Logger.Formatter.compile(Keyword.get(config, :format))
    metadata = Keyword.get(config, :metadata, []) |> configure_metadata()
    log_group = Keyword.get(config, :log_group, "cadet-logs")
    log_stream = Keyword.get(config, :log_stream, "#{node()}-#{:os.system_time(:second)}")

    %{
      state
      | level: level,
        format: format,
        metadata: metadata,
        log_group: log_group,
        log_stream: log_stream
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

  defp read_env do
    Application.get_env(:logger, __MODULE__, Application.get_env(:logger, :cloudwatch_logger, []))
  end

  defp configure_merge(env, options) do
    Keyword.merge(env, options, fn
      :colors, v1, v2 -> Keyword.merge(v1, v2)
      _, _v1, v2 -> v2
    end)
  end
end
