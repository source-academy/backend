defmodule Cadet.Chatbot.CourseDocumentsTest do
  use Cadet.DataCase

  import ExUnit.CaptureLog
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

    # The category is empty when the delete is decided on and occupied by the time it runs, which
    # is what happens when one admin files a document into a category another admin is deleting.
    # The restrict constraint on pixelbot_documents.category_id is what has to catch it: checking
    # the count in application code first leaves a window between the check and the delete, and
    # losing that race raises Ecto.ConstraintError — a 500 — instead of this 400.
    test "delete_category/2 refuses even when a count says the category is empty" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      {:ok, _} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "Filed a moment too late",
            s3_key: "course-#{course.id}/late.pdf",
            filename: "late.pdf",
            media_type: "application/pdf"
          }
        ])

      # A count of zero against an occupied category is exactly what an application-level check
      # sees when it reads before the other admin's insert commits. Deciding on that count would
      # send a doomed DELETE to Postgres and raise Ecto.ConstraintError.
      with_mock Repo, [:passthrough], aggregate: fn _queryable, :count, :id -> 0 end do
        assert {:error, {:bad_request, _message}} =
                 CourseDocuments.delete_category(course.id, category.id)
      end

      # The category survives, so the documents pointing at it keep a valid doc_type.
      assert [_] = CourseDocuments.list_categories(course.id)
    end

    test "delete_category/2 reports how many documents are in the way" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")

      for n <- 1..3 do
        {:ok, _} =
          CourseDocuments.create_documents(course.id, [
            %{
              category_id: category.id,
              title: "L#{n}",
              s3_key: "course-#{course.id}/l#{n}.pdf",
              filename: "l#{n}.pdf",
              media_type: "application/pdf"
            }
          ])
      end

      assert {:error, {:bad_request, "This category still has 3 document(s)"}} =
               CourseDocuments.delete_category(course.id, category.id)
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

    # `is_ecto_id` in the router accepts any binary, so a malformed id reaches these functions and
    # would raise Ecto.Query.CastError — a bare 500 — unless it is rejected before the query.
    test "category lookups return :not_found for a malformed ID" do
      course = insert(:course)

      assert {:error, :not_found} =
               CourseDocuments.rename_category(course.id, "not-an-id", "Lectures")

      assert {:error, :not_found} = CourseDocuments.delete_category(course.id, "not-an-id")
    end

    test "create_documents/2 rejects a malformed category ID as an invalid category" do
      course = insert(:course)

      assert {:error, {:bad_request, "Invalid category"}} =
               CourseDocuments.create_documents(course.id, [
                 %{
                   category_id: "not-an-id",
                   title: "L1A",
                   s3_key: "course-#{course.id}/l1a.pdf",
                   filename: "l1a.pdf",
                   media_type: "application/pdf"
                 }
               ])
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

  describe "documents" do
    setup do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")
      {:ok, course: course, category: category}
    end

    test "list_documents_for_category/2 returns only that category's documents", %{
      course: course,
      category: category
    } do
      {:ok, other_category} = CourseDocuments.create_category(course.id, "tutorial")
      {:ok, [lecture]} = create_document(course, category, "L1A", "l1a.pdf")
      {:ok, _tutorial} = create_document(course, other_category, "T1", "t1.pdf")

      assert [%{id: id}] = CourseDocuments.list_documents_for_category(course.id, category.id)
      assert id == lecture.id
    end

    # Two documents titled the same must not collide on doc_key: the key is what the routing LLM
    # names, and a duplicate would make one of them unreachable.
    test "create_documents/2 suffixes a doc_key already in use", %{
      course: course,
      category: category
    } do
      {:ok, [first]} = create_document(course, category, "Lecture 1A", "a.pdf")
      {:ok, [second]} = create_document(course, category, "Lecture 1A", "b.pdf")

      assert first.doc_key == "lecture-1a"
      assert second.doc_key == "lecture-1a-1"
    end

    test "create_documents/2 rejects a category from another course", %{course: course} do
      other_course = insert(:course)
      {:ok, other_category} = CourseDocuments.create_category(other_course.id, "lecture")

      assert {:error, {:bad_request, "Invalid category"}} =
               create_document(course, other_category, "L1A", "l1a.pdf")

      assert CourseDocuments.list_documents(course.id) == []
    end

    test "create_documents/2 rejects a whitespace-only title", %{
      course: course,
      category: category
    } do
      assert {:error, changeset} = create_document(course, category, "   ", "l1a.pdf")
      assert "can't be blank" in errors_on(changeset).title
    end

    test "create_documents/2 rolls back the whole batch when one entry fails", %{
      course: course,
      category: category
    } do
      assert {:error, _} =
               CourseDocuments.create_documents(course.id, [
                 %{
                   category_id: category.id,
                   title: "Good",
                   s3_key: "course-#{course.id}/good.pdf",
                   filename: "good.pdf",
                   media_type: "application/pdf"
                 },
                 %{category_id: category.id, title: "Bad"}
               ])

      assert CourseDocuments.list_documents(course.id) == []
    end

    test "update_document/3 rejects a category from another course", %{
      course: course,
      category: category
    } do
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")
      other_course = insert(:course)
      {:ok, other_category} = CourseDocuments.create_category(other_course.id, "lecture")

      assert {:error, {:bad_request, "Invalid category"}} =
               CourseDocuments.update_document(course.id, document.id, %{
                 category_id: other_category.id
               })
    end

    test "update_document/3 returns :not_found for a document in another course", %{
      course: course,
      category: category
    } do
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")
      other_course = insert(:course)

      assert {:error, :not_found} =
               CourseDocuments.update_document(other_course.id, document.id, %{title: "Mine"})
    end

    test "get_document/2 returns nil for a malformed id", %{course: course} do
      assert CourseDocuments.get_document(course.id, "not-an-id") == nil
      assert CourseDocuments.get_document(course.id, nil) == nil
      assert CourseDocuments.get_document(course.id, "12abc") == nil
    end

    test "get_document/2 accepts an id given as a string", %{course: course, category: category} do
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")

      assert %{id: id} = CourseDocuments.get_document(course.id, to_string(document.id))
      assert id == document.id
    end

    test "delete_document/2 removes the row and the stored object", %{
      course: course,
      category: category
    } do
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")
      parent = self()

      with_mock DocumentUploader, [:passthrough],
        delete: fn s3_key ->
          send(parent, {:deleted, s3_key})
          :ok
        end do
        assert {:ok, _} = CourseDocuments.delete_document(course.id, document.id)
        assert_receive {:deleted, s3_key}
        assert s3_key == document.s3_key
        assert CourseDocuments.list_documents(course.id) == []
      end
    end

    test "delete_document/2 returns :not_found for a document in another course", %{
      course: course,
      category: category
    } do
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")
      other_course = insert(:course)

      assert {:error, :not_found} =
               CourseDocuments.delete_document(other_course.id, document.id)
    end
  end

  describe "release dates" do
    setup do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")
      {:ok, course: course, category: category}
    end

    # An unreleased document is invisible to the routing LLM, which is the only thing keeping a
    # future week's material out of a student's answer.
    test "an unreleased document is absent from the map and unreachable by id", %{
      course: course,
      category: category
    } do
      {:ok, [document]} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "Week 13",
            release_date: Date.add(Date.utc_today(), 1),
            s3_key: "course-#{course.id}/w13.pdf",
            filename: "w13.pdf",
            media_type: "application/pdf"
          }
        ])

      assert CourseDocuments.build_document_map_json(course.id) == []
      assert CourseDocuments.get_documents_by_ids(course.id, [document.doc_key]) == []
    end

    test "a document released today is visible", %{course: course, category: category} do
      {:ok, [document]} =
        CourseDocuments.create_documents(course.id, [
          %{
            category_id: category.id,
            title: "Week 1",
            release_date: Date.utc_today(),
            s3_key: "course-#{course.id}/w1.pdf",
            filename: "w1.pdf",
            media_type: "application/pdf"
          }
        ])

      assert [entry] = CourseDocuments.build_document_map_json(course.id)
      assert entry["release_date"] == Date.utc_today()
      assert [_] = CourseDocuments.get_documents_by_ids(course.id, [document.doc_key])
    end

    # The key is omitted rather than sent as null, so the routing prompt does not spend tokens
    # telling the model about a date that does not exist.
    test "a document with no release date omits the key entirely", %{
      course: course,
      category: category
    } do
      {:ok, _} = create_document(course, category, "L1A", "l1a.pdf")

      assert [entry] = CourseDocuments.build_document_map_json(course.id)
      refute Jason.encode!(entry) =~ "release_date"
    end
  end

  describe "rename_document/3" do
    test "returns :not_found for a document in another course" do
      course = insert(:course)
      other_course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")

      assert {:error, :not_found} =
               CourseDocuments.rename_document(other_course.id, document.id, "new.pdf")
    end

    test "leaves the row untouched when storage refuses the rename" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")

      with_mock DocumentUploader, [:passthrough],
        rename: fn _old_key, _filename, _course_id ->
          {:error, {:bad_request, "Failed to rename document in S3"}}
        end do
        assert {:error, {:bad_request, "Failed to rename document in S3"}} =
                 CourseDocuments.rename_document(course.id, document.id, "new.pdf")

        assert CourseDocuments.get_document(course.id, document.id).filename == "l1a.pdf"
      end
    end

    test "updates the row when storage succeeds" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")
      {:ok, [document]} = create_document(course, category, "L1A", "l1a.pdf")

      with_mock DocumentUploader, [:passthrough],
        rename: fn _old_key, _filename, _course_id ->
          {:ok, %{s3_key: "course-#{course.id}/notes.tex", media_type: "text/x-tex"}}
        end do
        assert {:ok, renamed} =
                 CourseDocuments.rename_document(course.id, document.id, "notes.tex")

        assert renamed.filename == "notes.tex"
        assert renamed.media_type == "text/x-tex"
        assert renamed.s3_key == "course-#{course.id}/notes.tex"
        # The doc_key is derived from the title, so renaming the file must not move the document
        # out from under the routing prompt.
        assert renamed.doc_key == document.doc_key
      end
    end

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

    # A failed compensation leaves the object at the new key while the row still points at the
    # old one. Nothing more can be done automatically, so the caller still sees the original
    # failure and the mismatch is logged for an operator to reconcile.
    test "still reports the original failure when the compensating copy also fails" do
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

      with_mock DocumentUploader, [:passthrough],
        rename: fn _old_key, _filename, _course_id ->
          {:ok, %{s3_key: conflicting_document.s3_key, media_type: "application/pdf"}}
        end,
        restore_rename: fn _new_key, _old_key ->
          {:error, {:bad_request, "Failed to restore document in S3"}}
        end do
        log =
          capture_log(fn ->
            assert {:error, %Ecto.Changeset{}} =
                     CourseDocuments.rename_document(course.id, document.id, "conflict.pdf")
          end)

        assert log =~ "Failed to compensate document rename"
      end
    end
  end

  defp create_document(course, category, title, filename) do
    CourseDocuments.create_documents(course.id, [
      %{
        category_id: category.id,
        title: title,
        s3_key: "course-#{course.id}/#{filename}",
        filename: filename,
        media_type: "application/pdf"
      }
    ])
  end
end
