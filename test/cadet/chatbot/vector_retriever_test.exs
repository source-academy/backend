defmodule Cadet.Chatbot.VectorRetrieverTest do
  use Cadet.DataCase

  import Mock

  alias Cadet.Chatbot.{Embeddings, VectorRetriever}
  alias Ecto.Adapters.SQL

  setup do
    original_config = Application.get_env(:cadet, :vector_rag)

    Application.put_env(
      :cadet,
      :vector_rag,
      Keyword.merge(original_config, enabled: true, debug: true)
    )

    on_exit(fn -> Application.put_env(:cadet, :vector_rag, original_config) end)

    course = insert(:course)
    document_id = insert_document(course.id, "ready")
    insert_chunk(document_id, course.id, 0, "close chunk", vector(1.0))
    insert_chunk(document_id, course.id, 1, "far chunk", vector(-1.0))

    %{course: course}
  end

  test "returns an empty list when vector rag is disabled", %{course: course} do
    Application.put_env(:cadet, :vector_rag, enabled: false)
    assert VectorRetriever.retrieve("query", course_id: course.id) == {:ok, []}
  end

  test "returns chunks ordered by similarity", %{course: course} do
    with_mock Embeddings, embed: fn _query -> {:ok, vector(1.0)} end do
      assert {:ok, [first, second]} =
               VectorRetriever.retrieve("query", course_id: course.id, language: "python")

      assert first.content == "close chunk"
      assert first.metadata == %{"section" => "1.1"}
      assert second.content == "far chunk"
    end
  end

  test "filters chunks below the minimum similarity", %{course: course} do
    config = Application.get_env(:cadet, :vector_rag)
    Application.put_env(:cadet, :vector_rag, Keyword.put(config, :min_similarity, 0.5))

    with_mock Embeddings, embed: fn _query -> {:ok, vector(1.0)} end do
      assert {:ok, [%{content: "close chunk"}]} =
               VectorRetriever.retrieve("query", course_id: course.id, language: "python")
    end
  end

  test "returns an empty list without a course id" do
    assert VectorRetriever.retrieve("query", language: "python") == {:ok, []}
  end

  test "rejects unsupported languages", %{course: course} do
    assert VectorRetriever.retrieve("query", course_id: course.id, language: "javascript") ==
             {:error, :invalid_language}
  end

  test "returns embedding errors", %{course: course} do
    with_mock Embeddings, embed: fn _query -> {:error, :boom} end do
      assert VectorRetriever.retrieve("query", course_id: course.id, language: "python") ==
               {:error, :boom}
    end
  end

  test "returns query errors", %{course: course} do
    with_mock Embeddings, embed: fn _query -> {:ok, [1.0]} end do
      assert {:error, _} =
               VectorRetriever.retrieve("query", course_id: course.id, language: "python")
    end
  end

  test "rejects invalid options", %{course: course} do
    assert {:error, {:invalid_retrieval_options, _}} =
             VectorRetriever.retrieve("query", course_id: course.id, language: :python)
  end

  defp vector(first), do: [first | List.duplicate(0.0, 1535)]

  defp insert_document(course_id, status) do
    %{rows: [[id]]} =
      SQL.query!(
        Repo,
        """
        INSERT INTO rag_documents (course_id, title, source_filename, checksum, language, status,
          embedding_model, inserted_at, updated_at)
        VALUES ($1, 'SICP Python', 'sicpy.md', 'abc', 'python', $2, 'test', now(), now())
        RETURNING id
        """,
        [course_id, status]
      )

    id
  end

  defp insert_chunk(document_id, course_id, index, content, embedding) do
    SQL.query!(
      Repo,
      """
      INSERT INTO rag_chunks (rag_document_id, course_id, language, chunk_index, content,
        metadata, embedding, inserted_at, updated_at)
      VALUES ($1, $2, 'python', $3, $4, '{"section": "1.1"}', $5::text::vector, now(), now())
      """,
      [document_id, course_id, index, content, "[" <> Enum.join(embedding, ",") <> "]"]
    )
  end
end
