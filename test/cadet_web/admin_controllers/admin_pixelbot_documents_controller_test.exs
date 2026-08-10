defmodule CadetWeb.AdminPixelbotDocumentsControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Chatbot.CourseDocuments
  alias CadetWeb.AdminPixelbotDocumentsController

  test "upload/2 returns 400 for values that are not Plug uploads" do
    for files <- ["not-an-upload", %{"filename" => "notes.pdf"}, [["nested"]]] do
      conn =
        AdminPixelbotDocumentsController.upload(build_conn(), %{"files" => files})

      assert response(conn, :bad_request) == "Missing files"
    end
  end

  test "save/2 rolls back new documents when an existing-document update fails" do
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
