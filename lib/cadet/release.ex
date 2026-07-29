defmodule Cadet.Release do
  @moduledoc """
  Contains Release.migrate, to simplify running migrations from the command line
  """

  require Logger

  def migrate do
    Application.load(:cadet)

    Ecto.Migrator.with_repo(
      Cadet.Repo,
      &Ecto.Migrator.run(&1, Application.app_dir(:cadet, "priv/repo/migrations"), :up, all: true)
    )
  end

  def ingest_sicpy_textbook do
    Application.ensure_all_started(:cadet)

    case Cadet.Chatbot.TextbookIngestion.ingest_sicpy() do
      {:ok, {:ingested, document_id, chunk_count}} ->
        Logger.info("Ingested SICPy textbook document_id=#{document_id} chunks=#{chunk_count}")
        :ok

      {:ok, {:already_ingested, document_id, status}} ->
        Logger.info("SICPy textbook already ingested document_id=#{document_id} status=#{status}")
        :ok

      {:error, reason} ->
        raise "Failed to ingest SICPy textbook: #{inspect(reason)}"
    end
  end
end
