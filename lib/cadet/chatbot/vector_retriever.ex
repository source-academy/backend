defmodule Cadet.Chatbot.VectorRetriever do
  @moduledoc """
  Retrieves the most similar paragraph chunks for the legacy chat endpoint.
  """

  require Logger

  alias Cadet.Chatbot.{Embeddings, VectorRag}
  alias Cadet.Repo

  @type chunk :: %{
          id: integer(),
          content: String.t(),
          chunk_index: integer(),
          title: String.t(),
          source_filename: String.t(),
          metadata: map() | nil,
          similarity: float() | nil
        }

  @spec retrieve(String.t(), keyword()) :: {:ok, [chunk()]} | {:error, term()}
  def retrieve(query, opts) when is_binary(query) do
    if VectorRag.enabled?() do
      do_retrieve(query, opts)
    else
      {:ok, []}
    end
  end

  defp do_retrieve(query, opts) do
    with course_id when is_integer(course_id) <- Keyword.get(opts, :course_id),
         language when is_binary(language) <- Keyword.get(opts, :language),
         true <- VectorRag.valid_language?(language),
         {:ok, embedding} <- Embeddings.embed(query),
         {:ok, rows} <- query_chunks(embedding, course_id, language, Keyword.get(opts, :limit)) do
      {:ok, rows}
    else
      nil -> {:ok, []}
      false -> {:error, :invalid_language}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:invalid_retrieval_options, other}}
    end
  end

  defp query_chunks(embedding, course_id, language, limit) do
    limit = limit || VectorRag.top_k()
    vector = encode_vector(embedding)
    min_similarity = VectorRag.min_similarity()

    query = """
    SELECT
      rc.id,
      rc.content,
      rc.chunk_index,
      rd.title,
      rd.source_filename,
      rc.metadata,
      1 - (rc.embedding <=> $1::vector) AS similarity
    FROM rag_chunks rc
    JOIN rag_documents rd ON rd.id = rc.rag_document_id
    WHERE rc.course_id = $2
      AND rc.language = $3
      AND rd.status = 'ready'
      AND ($5::float8 IS NULL OR 1 - (rc.embedding <=> $1::vector) >= $5::float8)
    ORDER BY rc.embedding <=> $1::vector
    LIMIT $4
    """

    case Ecto.Adapters.SQL.query(Repo, query, [vector, course_id, language, limit, min_similarity]) do
      {:ok, %{rows: rows}} ->
        chunks = Enum.map(rows, &to_chunk/1)
        maybe_log_debug_chunks(chunks, course_id, language, limit)
        {:ok, chunks}

      {:error, error} ->
        Logger.error("VectorRetriever query failed: #{inspect(error)}")
        {:error, error}
    end
  end

  defp to_chunk([id, content, chunk_index, title, source_filename, metadata, similarity]) do
    %{
      id: id,
      content: content,
      chunk_index: chunk_index,
      title: title,
      source_filename: source_filename,
      metadata: metadata,
      similarity: similarity
    }
  end

  defp maybe_log_debug_chunks(chunks, course_id, language, limit) do
    if VectorRag.debug?() do
      formatted_chunks =
        chunks
        |> Enum.with_index(1)
        |> Enum.map_join("\n", fn {chunk, rank} ->
          metadata = chunk.metadata || %{}
          section = Map.get(metadata, "section") || "none"
          section_title = Map.get(metadata, "section_title") || "none"
          preview = chunk.content |> String.replace(~r/\s+/, " ") |> String.slice(0, 240)

          "#{rank}. id=#{chunk.id} chunk_index=#{chunk.chunk_index} " <>
            "similarity=#{format_similarity(chunk.similarity)} section=#{section} " <>
            "section_title=#{inspect(section_title)} title=#{inspect(chunk.title)} " <>
            "source=#{inspect(chunk.source_filename)} preview=#{inspect(preview)}"
        end)

      Logger.info("""
      Vector RAG retrieved #{length(chunks)} chunk(s) for course_id=#{course_id} language=#{language} limit=#{limit}
      #{formatted_chunks}
      """)
    end
  end

  defp format_similarity(nil), do: "nil"
  defp format_similarity(similarity), do: :erlang.float_to_binary(similarity, decimals: 4)

  defp encode_vector(embedding) do
    "[" <> Enum.map_join(embedding, ",", &to_string/1) <> "]"
  end
end
