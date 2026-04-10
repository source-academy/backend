defmodule Cadet.Chatbot.CourseDocuments do
  require Logger

  @cache_key {__MODULE__, :document_map}

  # Grab JSON from document_map
  def load_document_map do
    case :persistent_term.get(@cache_key, :not_cached) do
      :not_cached ->
        docs = read_document_map_from_disk()
        :persistent_term.put(@cache_key, docs)
        docs

      cached ->
        cached
    end
  end

  def invalidate_cache do
    :persistent_term.erase(@cache_key)
  end

  defp read_document_map_from_disk do
    path = Application.app_dir(:cadet, "priv/course_documents/document_map.json")

    case File.read(path) do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, docs} ->
            docs

          {:error, reason} ->
            Logger.error("Failed to parse document_map.json: #{inspect(reason)}")
            []
        end

      {:error, _} ->
        []
    end
  end

  # Strip S3 key before passing to gpt
  def build_document_map_json do
    load_document_map()
    |> Enum.map(fn doc ->
      Map.take(doc, ["id", "title", "description", "doc_type", "year", "week"])
    end)
  end

  def get_documents_by_ids(ids) when is_list(ids) do
    load_document_map()
    |> Enum.filter(fn doc -> doc["id"] in ids end)
  end
end
