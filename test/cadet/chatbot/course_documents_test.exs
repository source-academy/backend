defmodule Cadet.Chatbot.CourseDocumentsTest do
  use Cadet.DataCase

  import Mock

  alias Cadet.Chatbot.{CourseDocuments, DocumentUploader}

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
      refute Jason.encode!(entry) =~ "\"s3_key\""
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

  describe "validation" do
    test "create_documents/2 returns a changeset error for a missing title" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      assert {:error, changeset} =
               CourseDocuments.create_documents(course.id, [
                 %{
                   category_id: category.id,
                   s3_key: "course-#{course.id}/untitled.pdf",
                   filename: "untitled.pdf",
                   media_type: "application/pdf"
                 }
               ])

      assert "can't be blank" in errors_on(changeset).title
    end

    test "list_documents_for_category/2 returns an empty list for malformed IDs" do
      course = insert(:course)
      assert CourseDocuments.list_documents_for_category(course.id, "not-an-id") == []
    end

    test "update_document/3 normalizes a nil description" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      {:ok, [document]} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "L1A",
            description: "Old description",
            s3_key: "course-#{course.id}/l1a.pdf",
            filename: "l1a.pdf",
            media_type: "application/pdf"
          }
        ])

      assert {:ok, updated} =
               CourseDocuments.update_document(course.id, document.id, %{description: nil})

      assert updated.description == ""
    end
  end

  describe "rename_document/3" do
    test "restores the old S3 key when the database update fails" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      {:ok, [document, conflicting_document]} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "Original",
            s3_key: "course-#{course.id}/original.pdf",
            filename: "original.pdf",
            media_type: "application/pdf"
          },
          %{
            category_id: category.id,
            title: "Conflict",
            s3_key: "course-#{course.id}/conflict.pdf",
            filename: "conflict.pdf",
            media_type: "application/pdf"
          }
        ])

      parent = self()

      with_mock DocumentUploader, [:passthrough],
        rename: fn _old_key, _filename, _course_id ->
          {:ok, %{s3_key: conflicting_document.s3_key, media_type: "application/pdf"}}
        end,
        restore_rename: fn new_key, old_key ->
          send(parent, {:restored, new_key, old_key})
          :ok
        end do
        assert {:error, %Ecto.Changeset{}} =
                 CourseDocuments.rename_document(course.id, document.id, "conflict.pdf")

        assert_receive {:restored, new_key, old_key}
        assert new_key == conflicting_document.s3_key
        assert old_key == document.s3_key
      end
    end
  end
end
