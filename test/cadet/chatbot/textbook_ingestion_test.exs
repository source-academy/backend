defmodule Cadet.Chatbot.TextbookIngestionTest do
  use Cadet.DataCase

  import Mock

  alias Cadet.Chatbot.{Embeddings, TextbookIngestion}
  alias Ecto.Adapters.SQL

  @markdown """
  # Foreword to Structure and Interpretation of Computer Programs, 1984

  Foreword text.

  # 1 Building Abstractions with Functions

  ## 1.1 The Elements of Programming

  First paragraph about expressions.

  ```python
  # not a heading
  print(1)
  ```

  #### Exercise 1.1

  Second paragraph that is long enough to need splitting into more than one chunk of text.

  ## 1.2 Functions and the Processes They Generate
  """

  setup do
    %{course: insert(:course)}
  end

  test "ingests the textbook into documents and chunks", %{course: course} do
    with_mocks([
      {HTTPoison, [], get: fn _url, _headers, _opts -> ok(200, @markdown) end},
      {Embeddings, [], embed: fn _text -> {:ok, List.duplicate(0.1, 1536)} end}
    ]) do
      assert {:ok, {:ingested, document_id, chunk_count}} =
               TextbookIngestion.ingest_sicpy(
                 course_id: course.id,
                 chunk_size: 60,
                 chunk_overlap: 10
               )

      assert chunk_count > 3

      assert %{rows: [["ready"]]} =
               SQL.query!(Repo, "SELECT status FROM rag_documents WHERE id = $1", [document_id])

      %{rows: sections} =
        SQL.query!(Repo, "SELECT DISTINCT metadata->>'section' FROM rag_chunks", [])

      assert ["1.1"] in sections

      assert {:ok, {:already_ingested, ^document_id, "ready"}} =
               TextbookIngestion.ingest_sicpy(
                 course_id: course.id,
                 chunk_size: 60,
                 chunk_overlap: 10
               )
    end
  end

  test "retries failed embeddings before giving up", %{course: course} do
    with_mocks([
      {HTTPoison, [], get: fn _url, _headers, _opts -> ok(200, @markdown) end},
      {Embeddings, [], embed: fn _text -> {:error, :rate_limited} end},
      {Process, [:passthrough], sleep: fn _ms -> :ok end}
    ]) do
      assert TextbookIngestion.ingest_sicpy(course_id: course.id, embedding_retries: 1) ==
               {:error, :rate_limited}

      assert_called_exactly(Embeddings.embed(:_), 2)
    end
  end

  test "rolls back when a chunk cannot be stored", %{course: course} do
    with_mocks([
      {HTTPoison, [], get: fn _url, _headers, _opts -> ok(200, @markdown) end},
      {Embeddings, [], embed: fn _text -> {:ok, [0.1]} end}
    ]) do
      assert {:error, _} = TextbookIngestion.ingest_sicpy(course_id: course.id)
      assert %{rows: [[0]]} = SQL.query!(Repo, "SELECT count(*) FROM rag_documents", [])
    end
  end

  test "returns an error when the source cannot be fetched", %{course: course} do
    with_mock HTTPoison, get: fn _url, _headers, _opts -> ok(404, "missing") end do
      assert TextbookIngestion.ingest_sicpy(course_id: course.id) ==
               {:error, {:source_fetch_failed, 404, "missing"}}
    end

    with_mock HTTPoison, get: fn _url, _headers, _opts -> {:error, :nxdomain} end do
      assert TextbookIngestion.ingest_sicpy(course_id: course.id) == {:error, :nxdomain}
    end
  end

  test "returns an error when the source has no content", %{course: course} do
    with_mock HTTPoison, get: fn _url, _headers, _opts -> ok(200, "# 1 Only a heading\n") end do
      assert TextbookIngestion.ingest_sicpy(course_id: course.id) == {:error, :no_chunks_produced}
    end
  end

  test "requires a course id" do
    with_mock HTTPoison, get: fn _url, _headers, _opts -> ok(200, @markdown) end do
      assert TextbookIngestion.ingest_sicpy() == {:error, :missing_sicpy_course_id}
    end
  end

  defp ok(status, body), do: {:ok, %HTTPoison.Response{status_code: status, body: body}}
end
