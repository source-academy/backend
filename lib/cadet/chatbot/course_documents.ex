defmodule Cadet.Chatbot.CourseDocuments do
  #Grab JSON from doucment_map"
  def load_document_map do
    path = Application.app_dir(:cadet, "priv/course_documents/document_map.json")

    case File.read(path) do
      {:ok, contents} -> Jason.decode!(contents)
      {:error, _} -> []
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
