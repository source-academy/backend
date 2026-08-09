defmodule Cadet.Workers.PixelbotOrphanSweeper do
  @moduledoc """
  Daily job that deletes pixelbot S3 objects with no matching `pixelbot_documents` row.

  Documents are only inserted into the DB when an admin clicks Save (see
  Cadet.Chatbot.CourseDocuments.create_documents/2); an upload that's abandoned before that
  leaves the file in S3.
  """
  use Oban.Worker, queue: :default, max_attempts: 1
  require Logger

  alias Cadet.Repo
  alias Cadet.Chatbot.PixelbotDocument

  @grace_period_seconds 24 * 60 * 60
  @prefix "course-"

  @impl Oban.Worker
  def perform(_job) do
    config = Application.fetch_env!(:cadet, :rag_documents)
    bucket = config[:bucket]
    region = config[:region]
    request_opts = [region: region, host: "s3.#{region}.amazonaws.com", scheme: "https://"]

    known_keys = known_s3_keys()
    cutoff = grace_cutoff()

    orphans =
      bucket
      |> ExAws.S3.list_objects_v2(prefix: @prefix)
      |> ExAws.stream!(request_opts)
      |> Stream.filter(fn object ->
        not MapSet.member?(known_keys, object.key) and older_than?(object, cutoff)
      end)
      |> Enum.map(& &1.key)

    if orphans != [] do
      bucket
      |> ExAws.S3.delete_multiple_objects(orphans)
      |> ExAws.request(request_opts)
      |> case do
        {:ok, _} ->
          Logger.info("PixelbotOrphanSweeper: deleted #{length(orphans)} orphaned object(s)")

        {:error, reason} ->
          Logger.error("PixelbotOrphanSweeper: delete failed: #{inspect(reason)}")
      end
    else
      Logger.info("PixelbotOrphanSweeper: no orphans found")
    end

    :ok
  end

  defp known_s3_keys do
    PixelbotDocument
    |> Repo.all()
    |> MapSet.new(& &1.s3_key)
  end

  defp grace_cutoff do
    DateTime.utc_now()
    |> DateTime.add(-@grace_period_seconds, :second)
  end

  defp older_than?(%{last_modified: last_modified}, cutoff) do
    case DateTime.from_iso8601(last_modified) do
      {:ok, modified_at, _offset} -> DateTime.compare(modified_at, cutoff) == :lt
      _ -> false
    end
  end
end
