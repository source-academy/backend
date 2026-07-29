defmodule Cadet.Chatbot.TextbookIngestion do
  @moduledoc """
  Ingests the deployed SICPy Markdown textbook into the vector RAG tables.
  """

  alias Cadet.Chatbot.{Embeddings, VectorRag}
  alias Cadet.Repo

  @default_url "https://sicp.sourceacademy.org/sicpy.md"
  @default_title "SICP Python"
  @default_source_filename "sicpy.md"
  @default_chunk_size 3_600
  @default_chunk_overlap 600
  @default_embedding_retries 3
  @language "python"

  @document_headings [
    "Foreword to Structure and Interpretation of Computer Programs, 1984",
    "Prefaces to Structure and Interpretation of Computer Programs, 1996 & 1984",
    "References",
    "About the SICP JS Project"
  ]

  @spec ingest_sicpy(keyword()) ::
          {:ok, {:ingested, pos_integer(), non_neg_integer()}}
          | {:ok, {:already_ingested, pos_integer(), String.t()}}
          | {:error, term()}
  def ingest_sicpy(opts \\ []) do
    opts = defaults(opts)

    with {:ok, source_text} <- fetch_source(opts[:url]),
         {:ok, course_id} <- course_id(opts[:course_id]),
         checksum <- checksum(source_text),
         opts <- Keyword.put(opts, :course_id, course_id),
         {:ok, nil} <- existing_document(opts[:course_id], checksum),
         chunks when chunks != [] <- build_chunks(source_text, opts),
         {:ok, embedded_chunks} <- embed_chunks(chunks, opts[:embedding_retries]) do
      insert_document_with_chunks(opts, checksum, embedded_chunks)
    else
      {:ok, %{id: id, status: status}} -> {:ok, {:already_ingested, id, status}}
      [] -> {:error, :no_chunks_produced}
      {:error, reason} -> {:error, reason}
    end
  end

  defp defaults(opts) do
    [
      url: System.get_env("SICPY_MARKDOWN_URL") || @default_url,
      course_id: env_integer("SICPY_COURSE_ID"),
      title: System.get_env("SICPY_TITLE") || @default_title,
      source_filename: System.get_env("SICPY_SOURCE_FILENAME") || @default_source_filename,
      chunk_size: env_integer("SICPY_CHUNK_SIZE") || @default_chunk_size,
      chunk_overlap: env_integer("SICPY_CHUNK_OVERLAP") || @default_chunk_overlap,
      embedding_retries: env_integer("SICPY_EMBEDDING_RETRIES") || @default_embedding_retries
    ]
    |> Keyword.merge(opts)
  end

  defp env_integer(name) do
    case System.get_env(name) do
      nil -> nil
      "" -> nil
      value -> String.to_integer(value)
    end
  end

  defp course_id(course_id) when is_integer(course_id), do: {:ok, course_id}
  defp course_id(_course_id), do: {:error, :missing_sicpy_course_id}

  defp fetch_source(url) do
    headers = [{"User-Agent", "cadet-vector-rag-ingest/1.0"}]

    case HTTPoison.get(url, headers, recv_timeout: 60_000, follow_redirect: true) do
      {:ok, %{status_code: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status_code: status, body: body}} ->
        {:error, {:source_fetch_failed, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp checksum(text), do: :crypto.hash(:sha256, text) |> Base.encode16(case: :lower)

  defp existing_document(course_id, checksum) do
    query = """
    SELECT id, status
    FROM rag_documents
    WHERE course_id = $1 AND language = $2 AND checksum = $3
    """

    case Ecto.Adapters.SQL.query(Repo, query, [course_id, @language, checksum]) do
      {:ok, %{rows: [[id, status]]}} -> {:ok, %{id: id, status: status}}
      {:ok, %{rows: []}} -> {:ok, nil}
      {:error, error} -> {:error, error}
    end
  end

  defp build_chunks(source_text, opts) do
    source_text
    |> split_into_heading_sections(opts[:source_filename])
    |> Enum.flat_map(&split_section(&1, opts[:chunk_size], opts[:chunk_overlap]))
    |> Enum.reject(&heading_only_chunk?/1)
  end

  defp split_into_heading_sections(source_text, source_filename) do
    initial_metadata = %{
      "source_filename" => source_filename,
      "section" => nil,
      "section_title" => nil,
      "heading_path" => []
    }

    state = %{
      sections: [],
      lines: [],
      metadata: initial_metadata,
      heading_path: [],
      section: nil,
      section_title: nil,
      in_fenced_code: false,
      source_filename: source_filename
    }

    source_text
    |> String.split("\n")
    |> Enum.reduce(state, &consume_line/2)
    |> flush_section()
    |> Map.fetch!(:sections)
    |> Enum.reverse()
    |> Enum.reject(&(String.trim(&1.content) == ""))
  end

  defp consume_line(line, state) do
    fence? = Regex.match?(~r/^\s*(```|~~~)/, line)
    heading = if state.in_fenced_code, do: nil, else: markdown_heading(line)
    heading = if treat_as_heading?(heading, state.section), do: heading, else: nil

    state =
      if heading do
        state
        |> flush_section()
        |> start_section(line, heading)
      else
        %{state | lines: [line | state.lines]}
      end

    if fence?, do: %{state | in_fenced_code: not state.in_fenced_code}, else: state
  end

  defp markdown_heading(line) do
    case Regex.run(~r/^(##?#?#?#?#?)\s+(.+?)\s*$/, line) do
      [_, marks, title] -> {String.length(marks), String.trim(title)}
      _ -> nil
    end
  end

  defp treat_as_heading?(nil, _section), do: false

  defp treat_as_heading?({level, title}, section) do
    numbered_section?(title) or is_nil(section) or (level == 1 and title in @document_headings)
  end

  defp start_section(state, line, {level, title}) do
    heading_path = state.heading_path |> Enum.take(level - 1) |> Kernel.++([title])

    {section, section_title} =
      case numbered_section(title) do
        {section, section_title} -> {section, section_title}
        nil when level == 1 -> {nil, nil}
        nil -> {state.section, state.section_title}
      end

    metadata = %{
      "source_filename" => state.source_filename,
      "section" => section,
      "section_title" => section_title,
      "heading_path" => heading_path
    }

    %{
      state
      | lines: [line],
        metadata: metadata,
        heading_path: heading_path,
        section: section,
        section_title: section_title
    }
  end

  defp flush_section(%{lines: []} = state), do: state

  defp flush_section(state) do
    content =
      state.lines
      |> Enum.reverse()
      |> Enum.join("\n")
      |> String.trim()

    if content == "" do
      %{state | lines: []}
    else
      section = %{content: content, metadata: state.metadata}
      %{state | sections: [section | state.sections], lines: []}
    end
  end

  defp numbered_section(title) do
    case Regex.run(~r/^((?:\d+\.)*\d+)\s+(.+)$/, title) do
      [_, section, section_title] -> {section, String.trim(section_title)}
      _ -> nil
    end
  end

  defp numbered_section?(title), do: not is_nil(numbered_section(title))

  defp split_section(section, chunk_size, chunk_overlap) do
    section.content
    |> split_text(chunk_size, chunk_overlap)
    |> Enum.map(&%{content: &1, metadata: section.metadata})
  end

  defp split_text(text, chunk_size, chunk_overlap) do
    paragraphs = Regex.split(~r/\n\s*\n/, text, trim: true)

    {chunks, current} =
      Enum.reduce(paragraphs, {[], ""}, fn paragraph, {chunks, current} ->
        paragraph = String.trim(paragraph)

        cond do
          current == "" ->
            {chunks, paragraph}

          String.length(current) + String.length(paragraph) + 2 <= chunk_size ->
            {chunks, current <> "\n\n" <> paragraph}

          true ->
            {[current | chunks], overlap(current, chunk_overlap) <> paragraph}
        end
      end)

    [current | chunks]
    |> Enum.reverse()
    |> Enum.flat_map(&split_oversized_chunk(&1, chunk_size, chunk_overlap))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp split_oversized_chunk(chunk, chunk_size, chunk_overlap) do
    if String.length(chunk) <= chunk_size do
      [chunk]
    else
      do_split_oversized_chunk(chunk, chunk_size, max(chunk_size - chunk_overlap, 1), [])
    end
  end

  defp do_split_oversized_chunk("", _chunk_size, _step, chunks), do: Enum.reverse(chunks)

  defp do_split_oversized_chunk(chunk, chunk_size, step, chunks) do
    if String.length(chunk) <= chunk_size do
      Enum.reverse([chunk | chunks])
    else
      current = String.slice(chunk, 0, chunk_size)
      rest = String.slice(chunk, step, String.length(chunk) - step)
      do_split_oversized_chunk(rest, chunk_size, step, [current | chunks])
    end
  end

  defp overlap("", _chunk_overlap), do: ""

  defp overlap(text, chunk_overlap) do
    text
    |> String.slice(max(String.length(text) - chunk_overlap, 0), chunk_overlap)
    |> String.trim()
    |> case do
      "" -> ""
      overlap -> overlap <> "\n\n"
    end
  end

  defp heading_only_chunk?(%{content: chunk}) do
    lines = chunk |> String.trim() |> String.split("\n") |> Enum.reject(&(String.trim(&1) == ""))
    length(lines) == 1 and not is_nil(markdown_heading(hd(lines)))
  end

  defp insert_document(opts, checksum, chunks) do
    now = now()

    query = """
    INSERT INTO rag_documents (
      course_id, title, source_filename, checksum, language, status,
      embedding_model, metadata, inserted_at, updated_at
    )
    VALUES ($1, $2, $3, $4, $5, 'processing', $6, $7::jsonb, $8, $9)
    RETURNING id
    """

    metadata =
      Jason.encode!(%{
        chunk_size: opts[:chunk_size],
        chunk_overlap: opts[:chunk_overlap],
        total_chunks: length(chunks),
        section_count: section_count(chunks),
        section_aware: true,
        source_url: opts[:url]
      })

    params = [
      opts[:course_id],
      opts[:title],
      opts[:source_filename],
      checksum,
      @language,
      VectorRag.embedding_model(),
      metadata,
      now,
      now
    ]

    case Ecto.Adapters.SQL.query(Repo, query, params) do
      {:ok, %{rows: [[id]]}} -> {:ok, id}
      {:error, error} -> {:error, error}
    end
  end

  defp section_count(chunks) do
    chunks
    |> Enum.map(&get_in(&1, [:metadata, "section"]))
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
    |> MapSet.size()
  end

  defp insert_document_with_chunks(opts, checksum, chunks) do
    case Repo.transaction(fn ->
           with {:ok, document_id} <- insert_document(opts, checksum, chunks),
                :ok <- insert_chunks(document_id, chunks, opts) do
             mark_document_ready(document_id)
             {:ingested, document_id, length(chunks)}
           else
             {:error, reason} -> Repo.rollback(reason)
           end
         end) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_chunks(document_id, chunks, opts) do
    chunks
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {chunk, chunk_index}, :ok ->
      case insert_chunk(document_id, chunk, chunk_index, opts) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp embed_chunks(chunks, max_retries) do
    chunks
    |> Enum.reduce_while({:ok, []}, fn chunk, {:ok, embedded_chunks} ->
      case embed_with_retry(chunk.content, max_retries) do
        {:ok, embedding} ->
          {:cont, {:ok, [Map.put(chunk, :embedding, embedding) | embedded_chunks]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, embedded_chunks} -> {:ok, Enum.reverse(embedded_chunks)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp embed_with_retry(content, max_retries), do: embed_with_retry(content, max_retries, 0)

  defp embed_with_retry(content, max_retries, attempt) do
    case Embeddings.embed(content) do
      {:ok, embedding} ->
        {:ok, embedding}

      {:error, _reason} when attempt < max_retries ->
        Process.sleep(backoff_ms(attempt))
        embed_with_retry(content, max_retries, attempt + 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp backoff_ms(attempt), do: trunc(:math.pow(2, attempt) * 1_000)

  defp insert_chunk(document_id, chunk, chunk_index, opts) do
    with {:ok, _} <- insert_chunk_row(document_id, chunk, chunk_index, opts) do
      :ok
    end
  end

  defp insert_chunk_row(document_id, chunk, chunk_index, opts) do
    now = now()

    query = """
    INSERT INTO rag_chunks (
      rag_document_id, course_id, language, chunk_index, content,
      token_count, metadata, embedding, inserted_at, updated_at
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8::text::vector, $9, $10)
    """

    params = [
      document_id,
      opts[:course_id],
      @language,
      chunk_index,
      chunk.content,
      nil,
      Jason.encode!(chunk.metadata),
      vector_literal(chunk.embedding),
      now,
      now
    ]

    Ecto.Adapters.SQL.query(Repo, query, params)
  end

  defp mark_document_ready(document_id) do
    Ecto.Adapters.SQL.query!(
      Repo,
      "UPDATE rag_documents SET status = 'ready', updated_at = $1 WHERE id = $2",
      [now(), document_id]
    )
  end

  defp vector_literal(embedding), do: "[" <> Enum.map_join(embedding, ",", &to_string/1) <> "]"

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
