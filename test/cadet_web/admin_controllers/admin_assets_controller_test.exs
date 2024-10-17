defmodule CadetWeb.AdminAssetsControllerTest do
  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Cadet.Courses.Course
  alias Cadet.Repo
  alias CadetWeb.AdminAssetsController

  import Ecto.Query, only: [where: 2]

  setup_all do
    HTTPoison.start()
  end

  test "swagger" do
    AdminAssetsController.swagger_definitions()
    AdminAssetsController.swagger_path_index(nil)
    AdminAssetsController.swagger_path_upload(nil)
    AdminAssetsController.swagger_path_delete(nil)
  end

  describe "public access, unauthenticated" do
    test "GET /assets/:foldername", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url(course.id, "random_folder"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "DELETE /assets/:foldername/*filename", %{conn: conn} do
      course = insert(:course)
      conn = delete(conn, build_url(course.id, "random_folder/random_file"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "POST /assets/:foldername/*filename", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id, "random_folder/random_file"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "student permission, forbidden" do
    @tag authenticate: :student
    test "GET /assets/:foldername", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = get(conn, build_url(course_id, "testFolder"), %{})
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :student
    test "DELETE /assets/:foldername/*filename", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = delete(conn, build_url(course_id, "testFolder/testFile.png"))

      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :student
    test "POST /assets/:foldername/*filename", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn =
        post(conn, build_url(course_id, "testFolder/testFile.png"), %{
          :upload => build_upload("test/fixtures/upload.png")
        })

      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "non-admin staff permission, forbidden" do
    @tag authenticate: :staff
    test "GET /assets/:foldername", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = get(conn, build_url(course_id, "testFolder"), %{})

      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "DELETE /assets/:foldername/*filename", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = delete(conn, build_url(course_id, "testFolder/testFile.png"))

      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "POST /assets/:foldername/*filename", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn =
        post(conn, build_url(course_id, "testFolder/testFile.png"), %{
          :upload => build_upload("test/fixtures/upload.png")
        })

      assert response(conn, 403) =~ "Forbidden"
    end
  end

  describe "inaccessible folder name" do
    @tag authenticate: :admin
    test "index files", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = get(conn, build_url(course_id, "wrongFolder"))
      assert response(conn, 400) =~ "Invalid top-level folder name"
    end

    @tag authenticate: :admin
    test "delete file", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = delete(conn, build_url(course_id, "wrongFolder/randomFile"))

      assert response(conn, 400) =~ "Invalid top-level folder name"
    end

    @tag authenticate: :admin
    test "upload file", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn =
        post(conn, build_url(course_id, "wrongFolder/wrongUpload.png"), %{
          "upload" => build_upload("test/fixtures/upload.png")
        })

      assert response(conn, 400) =~ "Invalid top-level folder name"
    end
  end

  describe "ok request" do
    @tag authenticate: :admin, course_id: 117
    test "index file", %{conn: conn} do
      course_id = conn.assigns.course_id

      use_cassette "aws/controller_list_assets#1" do
        conn = get(conn, build_url(course_id, "testFolder"), %{})

        assert json_response(conn, 200) ===
                 ["testFolder/", "testFolder/test.png", "testFolder/test2.png"]
      end
    end

    @tag authenticate: :admin, course_id: 117
    test "delete file", %{conn: conn} do
      course_id = conn.assigns.course_id

      use_cassette "aws/controller_delete_asset#1" do
        conn = delete(conn, build_url(course_id, "testFolder/test2.png"))

        assert response(conn, 204)
      end
    end

    @tag authenticate: :admin, course_id: 117
    test "upload file", %{conn: conn} do
      course_id = conn.assigns.course_id

      use_cassette "aws/controller_upload_asset#1" do
        conn =
          post(conn, build_url(course_id, "testFolder/test.png"), %{
            "upload" => build_upload("test/fixtures/upload.png")
          })

        assert json_response(conn, 200) ===
                 "https://#{bucket()}.s3.amazonaws.com/courses-test/#{course_id}/testFolder/test.png"
      end
    end
  end

  describe "wrong file type" do
    @tag authenticate: :admin
    test "upload file", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn =
        post(conn, build_url(course_id, "testFolder/test.pdf"), %{
          "upload" => build_upload("test/fixtures/upload.pdf")
        })

      assert response(conn, 400) =~ "Invalid file type"
    end
  end

  describe "empty file name" do
    @tag authenticate: :admin
    test "upload file", %{conn: conn} do
      course_id = conn.assigns.course_id

      conn =
        post(conn, build_url(course_id, "testFolder"), %{
          "upload" => build_upload("test/fixtures/upload.png")
        })

      assert response(conn, 400) =~ "Empty file name"
    end

    @tag authenticate: :admin
    test "delete file", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = delete(conn, build_url(course_id, "testFolder"))
      assert response(conn, 400) =~ "Empty file name"
    end
  end

  describe "nested filename request" do
    @tag authenticate: :admin, course_id: 117
    test "delete file", %{conn: conn} do
      course_id = conn.assigns.course_id

      use_cassette "aws/controller_delete_asset#2" do
        conn = delete(conn, build_url(course_id, "testFolder/nestedFolder/test2.png"))

        assert response(conn, 204)
      end
    end

    @tag authenticate: :admin, course_id: 117
    test "upload file", %{conn: conn} do
      course_id = conn.assigns.course_id

      use_cassette "aws/controller_upload_asset#2" do
        conn =
          post(conn, build_url(course_id, "testFolder/nestedFolder/test.png"), %{
            "upload" => build_upload("test/fixtures/upload.png")
          })

        assert json_response(conn, 200) ===
                 "https://#{bucket()}.s3.amazonaws.com/courses-test/#{course_id}/testFolder/nestedFolder/test.png"
      end
    end
  end

  describe "course with custom assets_prefix" do
    @tag authenticate: :admin, course_id: 117
    test "index file", %{conn: conn} do
      course_id = conn.assigns.course_id

      set_course_prefix(course_id)

      use_cassette "aws/controller_list_assets#2" do
        conn = get(conn, build_url(course_id, "testFolder"), %{})

        assert json_response(conn, 200) ===
                 ["testFolder/", "testFolder/test.png", "testFolder/test2.png"]
      end
    end

    @tag authenticate: :admin, course_id: 117
    test "delete file", %{conn: conn} do
      course_id = conn.assigns.course_id

      set_course_prefix(course_id)

      use_cassette "aws/controller_delete_asset#3" do
        conn = delete(conn, build_url(course_id, "testFolder/nestedFolder/test2.png"))

        assert response(conn, 204)
      end
    end

    @tag authenticate: :admin, course_id: 117
    test "upload file", %{conn: conn} do
      course_id = conn.assigns.course_id

      set_course_prefix(course_id)

      use_cassette "aws/controller_upload_asset#3" do
        conn =
          post(conn, build_url(course_id, "testFolder/nestedFolder/test.png"), %{
            "upload" => build_upload("test/fixtures/upload.png")
          })

        assert json_response(conn, 200) ===
                 "https://#{bucket()}.s3.amazonaws.com/#{custom_prefix()}testFolder/nestedFolder/test.png"
      end
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/admin/assets/"
  defp build_url(course_id, url), do: "#{build_url(course_id)}/#{url}"

  defp build_upload(path, content_type \\ "image/png") do
    %Plug.Upload{path: path, filename: Path.basename(path), content_type: content_type}
  end

  defp set_course_prefix(course_id) do
    Course
    |> where(id: ^course_id)
    |> Repo.update_all(set: [assets_prefix: custom_prefix()])
  end

  defp bucket, do: :cadet |> Application.fetch_env!(:uploader) |> Keyword.get(:assets_bucket)

  defp custom_prefix, do: "this-is-a-prefix/"
end
