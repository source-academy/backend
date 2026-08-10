defmodule CadetWeb.AdminPixelbotDocumentsControllerTest do
  use CadetWeb.ConnCase

  import Mock

  alias Cadet.Chatbot.{CourseDocuments, DocumentUploader, MetadataGenerator}
  alias CadetWeb.AdminPixelbotDocumentsController

  defp documents_url(course_id), do: "/v2/courses/#{course_id}/admin/pixelbot_documents"
  defp categories_url(course_id), do: "/v2/courses/#{course_id}/admin/pixelbot_categories"

  defp insert_document(course_id, category_id, title, filename) do
    {:ok, [document]} =
      CourseDocuments.create_documents(course_id, [
        %{
          category_id: category_id,
          title: title,
          s3_key: "course-#{course_id}/#{filename}",
          filename: filename,
          media_type: "application/pdf"
        }
      ])

    document
  end

  describe "GET /pixelbot_documents (index)" do
    @tag authenticate: :admin
    test "renders this course's categories and documents", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")

      conn = get(conn, documents_url(course_id))

      assert %{"categories" => [rendered_category], "documents" => [rendered_document]} =
               json_response(conn, 200)

      assert rendered_category == %{"id" => category.id, "name" => "lecture"}

      assert rendered_document["id"] == document.id
      assert rendered_document["categoryId"] == category.id
      assert rendered_document["docKey"] == document.doc_key
      assert rendered_document["title"] == "L1A"
      assert rendered_document["filename"] == "l1a.pdf"
      assert rendered_document["mediaType"] == "application/pdf"
      assert rendered_document["releaseDate"] == nil
    end

    # The document view is what keeps s3_key out of the admin payload; the key is a storage
    # detail, and the frontend addresses documents by id.
    @tag authenticate: :admin
    test "never renders the s3 key", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      insert_document(course_id, category.id, "L1A", "l1a.pdf")

      conn = get(conn, documents_url(course_id))

      refute conn.resp_body =~ "s3"
    end

    @tag authenticate: :admin
    test "renders empty lists for a course with nothing set up", %{conn: conn} do
      conn = get(conn, documents_url(conn.assigns.course_id))

      assert json_response(conn, 200) == %{"categories" => [], "documents" => []}
    end

    @tag authenticate: :staff
    test "is forbidden to non-admin staff", %{conn: conn} do
      conn = get(conn, documents_url(conn.assigns.course_id))

      assert response(conn, :forbidden) == "Forbidden"
    end
  end

  describe "POST /pixelbot_categories (create_category)" do
    @tag authenticate: :admin
    test "creates a category", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn = post(conn, categories_url(course_id), %{"name" => "lecture"})

      assert %{"id" => id, "name" => "lecture"} = json_response(conn, 200)
      assert [%{id: ^id}] = CourseDocuments.list_categories(course_id)
    end

    @tag authenticate: :admin
    test "returns 400 when the name is missing", %{conn: conn} do
      conn = post(conn, categories_url(conn.assigns.course_id), %{})

      assert response(conn, :bad_request) == "Missing category name"
    end

    @tag authenticate: :admin
    test "returns 400 when the name is not a string", %{conn: conn} do
      conn = post(conn, categories_url(conn.assigns.course_id), %{"name" => %{"a" => 1}})

      assert response(conn, :bad_request) == "Missing category name"
    end

    # A duplicate name is the one failure an admin can reach by ordinary use, and it is what
    # exercises the changeset error response rather than a flat status code.
    @tag authenticate: :admin
    test "returns the changeset errors for a duplicate name", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, _} = CourseDocuments.create_category(course_id, "lecture")

      conn = post(conn, categories_url(course_id), %{"name" => "lecture"})

      assert %{"errors" => %{"course_id" => ["has already been taken"]}} =
               json_response(conn, 400)
    end
  end

  describe "PUT /pixelbot_categories/:category_id (rename_category)" do
    @tag authenticate: :admin
    test "renames a category", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")

      conn = put(conn, "#{categories_url(course_id)}/#{category.id}", %{"name" => "Lectures"})

      assert json_response(conn, 200) == %{"id" => category.id, "name" => "Lectures"}
    end

    @tag authenticate: :admin
    test "returns 404 for a category in another course", %{conn: conn} do
      other_course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(other_course.id, "lecture")

      conn =
        put(conn, "#{categories_url(conn.assigns.course_id)}/#{category.id}", %{"name" => "Mine"})

      assert response(conn, :not_found) == "Category not found"
    end

    @tag authenticate: :admin
    test "returns the changeset errors for a blank name", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")

      conn = put(conn, "#{categories_url(course_id)}/#{category.id}", %{"name" => ""})

      assert %{"errors" => %{"name" => ["can't be blank"]}} = json_response(conn, 400)
    end
  end

  describe "DELETE /pixelbot_categories/:category_id (delete_category)" do
    @tag authenticate: :admin
    test "deletes an empty category", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "empty")

      conn = delete(conn, "#{categories_url(course_id)}/#{category.id}")

      assert response(conn, :no_content) == ""
      assert CourseDocuments.list_categories(course_id) == []
    end

    @tag authenticate: :admin
    test "refuses to delete a category that still has documents", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      insert_document(course_id, category.id, "L1A", "l1a.pdf")

      conn = delete(conn, "#{categories_url(course_id)}/#{category.id}")

      assert response(conn, :bad_request) =~ "1 document"
    end

    @tag authenticate: :admin
    test "returns 404 for an unknown category", %{conn: conn} do
      conn = delete(conn, "#{categories_url(conn.assigns.course_id)}/0")

      assert response(conn, :not_found) == "Category not found"
    end
  end

  describe "POST /pixelbot_documents/upload (upload)" do
    @tag authenticate: :admin
    test "returns 400 when no files are given", %{conn: conn} do
      conn = post(conn, "#{documents_url(conn.assigns.course_id)}/upload", %{})

      assert response(conn, :bad_request) == "Missing files"
    end

    test "returns 400 for values that are not Plug uploads" do
      for files <- ["not-an-upload", %{"filename" => "notes.pdf"}, [["nested"]], []] do
        conn = AdminPixelbotDocumentsController.upload(build_conn(), %{"files" => files})

        assert response(conn, :bad_request) == "Missing files"
      end
    end

    test "stores each file and returns the LLM-proposed metadata for review" do
      course = insert(:course)
      conn = assign(build_conn(), :course_reg, %{course_id: course.id, course: course})
      upload = plug_upload("l1a.pdf", "lecture one")

      with_mock DocumentUploader, [:passthrough],
        upload: fn _filename, _path, _course_id, _claimed ->
          {:ok, %{s3_key: "course-#{course.id}/l1a.pdf", media_type: "application/pdf"}}
        end do
        with_mock MetadataGenerator, [:passthrough],
          generate: fn _filename, _base64, _media_type, _model ->
            %{title: "L1A", description: "Covers recursion."}
          end do
          conn = AdminPixelbotDocumentsController.upload(conn, %{"files" => [upload]})

          assert %{"entries" => [entry]} = json_response(conn, 200)

          assert entry == %{
                   "status" => "ready",
                   "s3Key" => "course-#{course.id}/l1a.pdf",
                   "filename" => "l1a.pdf",
                   "mediaType" => "application/pdf",
                   "title" => "L1A",
                   "description" => "Covers recursion.",
                   # The LLM cannot know a release date; the admin fills it in before saving.
                   "releaseDate" => nil
                 }
        end
      end
    end

    # One rejected file must not sink the rest of the batch: the admin gets a per-file verdict
    # and can fix and re-upload only what failed.
    test "reports a per-file error without dropping the files that succeeded" do
      course = insert(:course)
      conn = assign(build_conn(), :course_reg, %{course_id: course.id, course: course})
      good = plug_upload("l1a.pdf", "lecture one")
      bad = plug_upload("virus.exe", "nope")

      with_mock DocumentUploader, [:passthrough],
        upload: fn
          "virus.exe", _path, _course_id, _claimed ->
            {:error, {:bad_request, "Unsupported file type .exe"}}

          filename, _path, _course_id, _claimed ->
            {:ok, %{s3_key: "course-#{course.id}/#{filename}", media_type: "application/pdf"}}
        end do
        with_mock MetadataGenerator, [:passthrough],
          generate: fn _filename, _base64, _media_type, _model ->
            %{title: "L1A", description: ""}
          end do
          conn = AdminPixelbotDocumentsController.upload(conn, %{"files" => [good, bad]})

          assert %{"entries" => [first, second]} = json_response(conn, 200)

          # Order is preserved, so the admin can match verdicts to the files they picked.
          assert first["status"] == "ready"
          assert first["filename"] == "l1a.pdf"

          assert second == %{
                   "status" => "error",
                   "filename" => "virus.exe",
                   "error" => "Unsupported file type .exe"
                 }
        end
      end
    end

    # No row exists yet at upload time, so an unreadable temp file has to degrade to a blank
    # description rather than fail the upload the admin has already paid the S3 write for.
    test "falls back to a filename-derived title when the file cannot be read for metadata" do
      course = insert(:course)
      conn = assign(build_conn(), :course_reg, %{course_id: course.id, course: course})
      upload = %Plug.Upload{filename: "l1a.pdf", path: "/nonexistent/l1a.pdf"}

      with_mock DocumentUploader, [:passthrough],
        upload: fn _filename, _path, _course_id, _claimed ->
          {:ok, %{s3_key: "course-#{course.id}/l1a.pdf", media_type: "application/pdf"}}
        end do
        conn = AdminPixelbotDocumentsController.upload(conn, %{"files" => [upload]})

        assert %{"entries" => [entry]} = json_response(conn, 200)
        assert entry["status"] == "ready"
        assert entry["title"] == "l1a"
        assert entry["description"] == ""
      end
    end
  end

  describe "PUT /pixelbot_documents (save)" do
    @tag authenticate: :admin
    test "creates the new entries and returns the refreshed index", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [
            %{
              "categoryId" => category.id,
              "title" => "L1A",
              "description" => "Covers recursion.",
              "releaseDate" => "2026-01-01",
              "s3Key" => "course-#{course_id}/l1a.pdf",
              "filename" => "l1a.pdf",
              "mediaType" => "application/pdf"
            }
          ]
        })

      assert %{"documents" => [document]} = json_response(conn, 200)
      assert document["title"] == "L1A"
      assert document["description"] == "Covers recursion."
      assert document["releaseDate"] == "2026-01-01"
    end

    @tag authenticate: :admin
    test "applies edits to existing entries", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      {:ok, other_category} = CourseDocuments.create_category(course_id, "tutorial")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [
            %{
              "id" => document.id,
              "categoryId" => other_category.id,
              "title" => "Lecture 1A",
              "description" => "Now with a description."
            }
          ]
        })

      assert %{"documents" => [rendered]} = json_response(conn, 200)
      assert rendered["title"] == "Lecture 1A"
      assert rendered["categoryId"] == other_category.id
      assert rendered["description"] == "Now with a description."
    end

    # The s3Key arrives from the client, so it is re-checked against this course's prefix. Without
    # this an admin could graft another course's uploaded object onto their own document map.
    @tag authenticate: :admin
    test "rejects an s3 key belonging to another course", %{conn: conn} do
      course_id = conn.assigns.course_id
      other_course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [
            %{
              "categoryId" => category.id,
              "title" => "Stolen",
              "s3Key" => "course-#{other_course.id}/secret.pdf",
              "filename" => "secret.pdf",
              "mediaType" => "application/pdf"
            }
          ]
        })

      assert response(conn, :bad_request) == "Invalid document reference"
      assert CourseDocuments.list_documents(course_id) == []
    end

    @tag authenticate: :admin
    test "rejects a new entry with no s3 key at all", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [%{"categoryId" => category.id, "title" => "No file"}]
        })

      assert response(conn, :bad_request) == "Invalid document reference"
    end

    @tag authenticate: :admin
    test "rejects a category belonging to another course", %{conn: conn} do
      course_id = conn.assigns.course_id
      other_course = insert(:course)
      {:ok, other_category} = CourseDocuments.create_category(other_course.id, "lecture")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [
            %{
              "categoryId" => other_category.id,
              "title" => "L1A",
              "s3Key" => "course-#{course_id}/l1a.pdf",
              "filename" => "l1a.pdf",
              "mediaType" => "application/pdf"
            }
          ]
        })

      assert response(conn, :bad_request) == "Invalid category"
      assert CourseDocuments.list_documents(course_id) == []
    end

    @tag authenticate: :admin
    test "returns 400 when entries are missing", %{conn: conn} do
      conn = put(conn, documents_url(conn.assigns.course_id), %{})

      assert response(conn, :bad_request) == "Missing entries"
    end

    @tag authenticate: :admin
    test "returns 400 when entries is not a list", %{conn: conn} do
      conn = put(conn, documents_url(conn.assigns.course_id), %{"entries" => "one"})

      assert response(conn, :bad_request) == "Missing entries"
    end

    # A new entry that fails validation comes back as changeset errors rather than a flat message,
    # so the frontend can mark the offending field on the row the admin is still editing.
    @tag authenticate: :admin
    test "returns the changeset errors for a new entry with a blank title", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [
            %{
              "categoryId" => category.id,
              "title" => "   ",
              "s3Key" => "course-#{course_id}/untitled.pdf",
              "filename" => "untitled.pdf",
              "mediaType" => "application/pdf"
            }
          ]
        })

      assert %{"errors" => %{"title" => ["can't be blank"]}} = json_response(conn, 400)
      assert CourseDocuments.list_documents(course_id) == []
    end

    @tag authenticate: :admin
    test "returns the changeset errors when an edit to an existing entry is invalid", %{
      conn: conn
    } do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [%{"id" => document.id, "title" => nil}]
        })

      assert %{"errors" => %{"title" => ["can't be blank"]}} = json_response(conn, 400)
      assert CourseDocuments.get_document(course_id, document.id).title == "L1A"
    end

    @tag authenticate: :admin
    test "rejects an edit that moves a document into another course's category", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")

      other_course = insert(:course)
      {:ok, other_category} = CourseDocuments.create_category(other_course.id, "lecture")

      conn =
        put(conn, documents_url(course_id), %{
          "entries" => [%{"id" => document.id, "categoryId" => other_category.id}]
        })

      assert response(conn, :bad_request) == "Invalid category"
      assert CourseDocuments.get_document(course_id, document.id).category_id == category.id
    end

    test "rolls back new documents when an existing-document update fails" do
      course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(course.id, "lecture")
      conn = assign(build_conn(), :course_reg, %{course_id: course.id})

      conn =
        AdminPixelbotDocumentsController.save(conn, %{
          "entries" => [
            %{
              "categoryId" => category.id,
              "title" => "L1A",
              "s3Key" => "course-#{course.id}/l1a.pdf",
              "filename" => "l1a.pdf",
              "mediaType" => "application/pdf"
            },
            %{"id" => -1, "categoryId" => category.id, "title" => "Missing"}
          ]
        })

      assert response(conn, :bad_request) == "Document not found"
      assert CourseDocuments.list_documents(course.id) == []
    end
  end

  describe "PUT /pixelbot_documents/:document_id/rename" do
    @tag authenticate: :admin
    test "renames the stored file", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")

      with_mock DocumentUploader, [:passthrough],
        rename: fn _old_key, _filename, _course_id ->
          {:ok, %{s3_key: "course-#{course_id}/lecture-1a.pdf", media_type: "application/pdf"}}
        end do
        conn =
          put(conn, "#{documents_url(course_id)}/#{document.id}/rename", %{
            "filename" => "lecture-1a.pdf"
          })

        assert %{"filename" => "lecture-1a.pdf"} = json_response(conn, 200)
      end
    end

    @tag authenticate: :admin
    test "returns 404 for a document in another course", %{conn: conn} do
      other_course = insert(:course)
      {:ok, category} = CourseDocuments.create_category(other_course.id, "lecture")
      document = insert_document(other_course.id, category.id, "L1A", "l1a.pdf")

      conn =
        put(conn, "#{documents_url(conn.assigns.course_id)}/#{document.id}/rename", %{
          "filename" => "mine.pdf"
        })

      assert response(conn, :not_found) == "Document not found"
    end

    # Storage moved the object but the row could not be updated, because another document in the
    # course already claims that key. The compensating copy puts the object back, and the admin
    # sees why the rename did not take.
    @tag authenticate: :admin
    test "returns the changeset errors when the new key collides with another document", %{
      conn: conn
    } do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")
      conflicting = insert_document(course_id, category.id, "L1B", "l1b.pdf")

      with_mock DocumentUploader, [:passthrough],
        rename: fn _old_key, _filename, _course_id ->
          {:ok, %{s3_key: conflicting.s3_key, media_type: "application/pdf"}}
        end,
        restore_rename: fn _new_key, _old_key -> :ok end do
        conn =
          put(conn, "#{documents_url(course_id)}/#{document.id}/rename", %{
            "filename" => "l1b.pdf"
          })

        assert %{"errors" => %{"s3_key" => ["has already been taken"]}} = json_response(conn, 400)
        assert CourseDocuments.get_document(course_id, document.id).filename == "l1a.pdf"
      end
    end

    @tag authenticate: :admin
    test "surfaces the storage error for an unsupported extension", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")

      conn =
        put(conn, "#{documents_url(course_id)}/#{document.id}/rename", %{
          "filename" => "l1a.exe"
        })

      assert response(conn, :bad_request) == "Unsupported file type .exe"
    end
  end

  describe "DELETE /pixelbot_documents/:document_id" do
    @tag authenticate: :admin
    test "deletes the row and the stored object", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")
      parent = self()

      with_mock DocumentUploader, [:passthrough],
        delete: fn s3_key ->
          send(parent, {:deleted, s3_key})
          :ok
        end do
        conn = delete(conn, "#{documents_url(course_id)}/#{document.id}")

        assert response(conn, :no_content) == ""
        assert_receive {:deleted, s3_key}
        assert s3_key == document.s3_key
        assert CourseDocuments.list_documents(course_id) == []
      end
    end

    @tag authenticate: :admin
    test "returns 404 for an unknown document", %{conn: conn} do
      conn = delete(conn, "#{documents_url(conn.assigns.course_id)}/0")

      assert response(conn, :not_found) == "Document not found"
    end

    # `is_ecto_id` lets any binary through, so a malformed id would reach Ecto and raise a
    # CastError — a 500 — unless it is rejected first.
    @tag authenticate: :admin
    test "returns 404 rather than crashing on a malformed id", %{conn: conn} do
      conn = delete(conn, "#{documents_url(conn.assigns.course_id)}/not-an-id")

      assert response(conn, :not_found) == "Document not found"
    end
  end

  describe "GET /pixelbot_documents/map_preview" do
    @tag authenticate: :admin
    test "returns exactly what the routing LLM would be shown", %{conn: conn} do
      course_id = conn.assigns.course_id
      {:ok, category} = CourseDocuments.create_category(course_id, "lecture")
      document = insert_document(course_id, category.id, "L1A", "l1a.pdf")

      conn = get(conn, "#{documents_url(course_id)}/map_preview")

      assert %{"documentMap" => [entry]} = json_response(conn, 200)

      assert entry == %{
               "id" => document.doc_key,
               "title" => "L1A",
               "description" => "",
               "doc_type" => "lecture"
             }
    end

    @tag authenticate: :admin
    test "returns an empty map for a course with no documents", %{conn: conn} do
      conn = get(conn, "#{documents_url(conn.assigns.course_id)}/map_preview")

      assert json_response(conn, 200) == %{"documentMap" => []}
    end
  end

  defp plug_upload(filename, contents) do
    path = Path.join(System.tmp_dir!(), "#{System.unique_integer([:positive])}-#{filename}")
    File.write!(path, contents)
    on_exit(fn -> File.rm(path) end)

    %Plug.Upload{filename: filename, path: path}
  end
end
