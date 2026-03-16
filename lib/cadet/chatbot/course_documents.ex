defmodule Cadet.Chatbot.CourseDocuments do
  @moduledoc """
  Loads and queries the course document map from a local JSON file.
  The document map is used by the RAG pipeline to determine which
  documents are relevant to a student's question.
  """

  @doc """
  Loads and decodes the document_map.json file.
  Returns a list of document maps.
  """
  def load_document_map do
    path = Application.app_dir(:cadet, "priv/course_documents/document_map.json")

    case File.read(path) do
      {:ok, contents} -> Jason.decode!(contents)
      {:error, _} -> []
    end
  end

  @doc """
  Returns the document map as a JSON string suitable for the routing prompt.
  Strips the s3_key field since the LLM doesn't need it.
  """
  def build_document_map_json do
    load_document_map()
    |> Enum.map(fn doc ->
      Map.take(doc, ["id", "title", "description", "doc_type", "year", "week"])
    end)
  end

  @doc """
  Filters the document map to only include documents with the given IDs.
  Returns full document maps (including s3_key) for fetching from S3.
  """
  def get_documents_by_ids(ids) when is_list(ids) do
    load_document_map()
    |> Enum.filter(fn doc -> doc["id"] in ids end)
  end
end
