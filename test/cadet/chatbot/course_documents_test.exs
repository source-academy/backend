defmodule Cadet.Chatbot.CourseDocumentsTest do
  use Cadet.DataCase

  alias Cadet.Chatbot.CourseDocuments

  describe "categories" do
    test "create_category/2 creates a category for a course" do
      course = insert(:course)
      assert {:ok, category} = CourseDocuments.create_category(course.id, "lecture")
      assert category.name == "lecture"
      assert category.course_id == course.id
    end

    test "rename_category/3 updates the name with no cascade to documents" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      {:ok, [document]} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "L1A",
            s3_key: "course-#{course.id}/l1a.pdf",
            filename: "l1a.pdf",
            media_type: "application/pdf"
          }
        ])

      assert {:ok, _renamed} = CourseDocuments.rename_category(course.id, category.id, "Lectures")

      [map_entry] = CourseDocuments.build_document_map_json(course.id)
      assert map_entry["doc_type"] == "Lectures"
      assert map_entry["id"] == document.doc_key
    end

    test "delete_category/2 is blocked while it still has documents" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      {:ok, _} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "L1A",
            s3_key: "course-#{course.id}/l1a.pdf",
            filename: "l1a.pdf",
            media_type: "application/pdf"
          }
        ])

      assert {:error, {:bad_request, message}} =
               CourseDocuments.delete_category(course.id, category.id)

      assert message =~ "1 document"
    end

    test "delete_category/2 succeeds when empty" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "empty")
      assert {:ok, _} = CourseDocuments.delete_category(course.id, category.id)
    end
  end

  describe "build_document_map_json/1" do
    test "returns [] for a course with no documents" do
      course = insert(:course)
      assert CourseDocuments.build_document_map_json(course.id) == []
    end

    test "never includes s3_key" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      {:ok, _} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "L1A",
            s3_key: "course-#{course.id}/l1a.pdf",
            filename: "l1a.pdf",
            media_type: "application/pdf"
          }
        ])

      [entry] = CourseDocuments.build_document_map_json(course.id)
      refute Map.has_key?(entry, "s3_key")
    end

    test "only includes documents belonging to the given course" do
      course_a = insert(:course)
      course_b = insert(:course)
      {:ok, category_a} = CourseDocuments.create_category(course_a.id, "lecture")

      {:ok, _} =
        CourseDocuments.create_documents(course_a.id, [
          %{
            category_id: category_a.id,
            title: "L1A",
            s3_key: "course-#{course_a.id}/l1a.pdf",
            filename: "l1a.pdf",
            media_type: "application/pdf"
          }
        ])

      assert CourseDocuments.build_document_map_json(course_b.id) == []
      assert length(CourseDocuments.build_document_map_json(course_a.id)) == 1
    end
  end

  describe "get_documents_by_ids/2" do
    test "returns empty list for non-matching ids" do
      course = insert(:course)
      assert CourseDocuments.get_documents_by_ids(course.id, ["nonexistent_id"]) == []
    end

    test "returns empty list for empty input" do
      course = insert(:course)
      assert CourseDocuments.get_documents_by_ids(course.id, []) == []
    end

    test "does not return another course's documents" do
      course_a = insert(:course)
      course_b = insert(:course)
      {:ok, category_a} = CourseDocuments.create_category(course_a.id, "lecture")

      {:ok, [document]} =
        CourseDocuments.create_documents(course_a.id, [
          %{
            category_id: category_a.id,
            title: "L1A",
            s3_key: "course-#{course_a.id}/l1a.pdf",
            filename: "l1a.pdf",
            media_type: "application/pdf"
          }
        ])

      assert CourseDocuments.get_documents_by_ids(course_b.id, [document.doc_key]) == []

      assert [%{"s3_key" => s3_key}] =
               CourseDocuments.get_documents_by_ids(course_a.id, [document.doc_key])

      assert s3_key == document.s3_key
    end
  end
end
