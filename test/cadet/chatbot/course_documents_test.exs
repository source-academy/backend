defmodule Cadet.Chatbot.CourseDocumentsTest do
  use ExUnit.Case

  alias Cadet.Chatbot.CourseDocuments

  setup do
    CourseDocuments.invalidate_cache()
    :ok
  end

  describe "load_document_map/0" do
    test "returns a list" do
      result = CourseDocuments.load_document_map()
      assert is_list(result)
    end

    test "caches the result on subsequent calls" do
      first = CourseDocuments.load_document_map()
      second = CourseDocuments.load_document_map()
      assert first == second
    end
  end

  describe "invalidate_cache/0" do
    test "clears the cached document map" do
      CourseDocuments.load_document_map()
      CourseDocuments.invalidate_cache()
      # Should not raise after invalidation
      assert is_list(CourseDocuments.load_document_map())
    end
  end

  describe "build_document_map_json/0" do
    test "returns list of maps without s3_key" do
      result = CourseDocuments.build_document_map_json()
      assert is_list(result)

      Enum.each(result, fn doc ->
        refute Map.has_key?(doc, "s3_key")
        assert is_map(doc)
      end)
    end
  end

  describe "get_documents_by_ids/1" do
    test "returns empty list for non-matching ids" do
      assert CourseDocuments.get_documents_by_ids(["nonexistent_id"]) == []
    end

    test "returns empty list for empty input" do
      assert CourseDocuments.get_documents_by_ids([]) == []
    end
  end
end
