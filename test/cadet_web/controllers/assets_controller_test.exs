defmodule CadetWeb.AssetsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AssetsController

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  test "swagger" do
    AssetsController.swagger_path_index(nil)
    AssetsController.swagger_path_upload(nil)
    AssetsController.swagger_path_delete(nil)
  end

  describe "public access, unauthenticated" do
    test "GET /assets/:folder_name", %{conn: conn} do
      conn = get(conn, build_url("random_folder"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "GET /assets/delete", %{conn: conn} do
      conn = delete(conn, build_url("delete"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    test "GET /assets/upload", %{conn: conn} do
      conn = post(conn, build_url("upload"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "student permission, forbidden" do
    @tag authenticate: :student
    test "GET /assets/:folder_name", %{conn: conn} do
      conn = get(conn, build_url("testFolder"), %{})
      assert response(conn, 403) =~ "User not allowed to manage assets"
    end

    @tag authenticate: :student
    test "GET /assets/delete", %{conn: conn} do
      conn =
        delete(conn, build_url("delete"), %{
          "folderName" => "testFolder",
          "filename" => "test.png"
        })

      assert response(conn, 403) =~ "User not allowed to manage assets"
    end

    @tag authenticate: :student
    test "GET /assets/upload", %{conn: conn} do
      conn =
        post(conn, build_url("upload"), %{
          :upload => build_upload("test/fixtures/upload.png"),
          :details => "{\"folderName\" : \"wrongFolder\"}"
        })

      assert response(conn, 403) =~ "User not allowed to manage assets"
    end
  end

  describe "inaccessible folder name" do
    @tag authenticate: :staff
    test "index files", %{conn: conn} do
      conn = get(conn, build_url("wrongFolder"), %{})
      assert response(conn, 400) =~ "Bad Request"
    end

    @tag authenticate: :staff
    test "delete file", %{conn: conn} do
      conn =
        delete(conn, build_url("delete"), %{
          "folderName" => "wrongFolder",
          "filename" => "randomFile"
        })

      assert response(conn, 400) =~ "Bad Request"
    end

    @tag authenticate: :staff
    test "upload file", %{conn: conn} do
      conn =
        post(conn, build_url("upload"), %{
          "upload" => build_upload("test/fixtures/upload.png"),
          "details" => "{\"folderName\" : \"wrongFolder\"}"
        })

      assert response(conn, 400) =~ "Bad Request"
    end
  end

  describe "ok request" do
    @tag authenticate: :staff
    test "index file", %{conn: conn} do
      use_cassette "aws/list_assets#1" do
        conn = get(conn, build_url("testFolder"), %{})

        assert response(conn, 200) ===
                 "[\"testFolder/\",\"testFolder/test.png\",\"testFolder/test2.png\"]"
      end
    end

    @tag authenticate: :staff
    test "delete file", %{conn: conn} do
      use_cassette "aws/list_assets#2" do
        conn =
          delete(conn, build_url("delete"), %{
            "folderName" => "testFolder",
            "filename" => "test.png"
          })

        assert response(conn, 200) === "\"ok\""
      end
    end

    @tag authenticate: :staff
    test "upload file", %{conn: conn} do
      use_cassette "aws/list_assets#4" do
        conn =
          post(conn, build_url("upload"), %{
            "upload" => build_upload("test/fixtures/upload.png"),
            "details" => "{\"folderName\" : \"testFolder\"}"
          })

        assert response(conn, 200) ===
                 "{\"s3_url\":\"http://source-academy-assets.s3.amazonaws.com/testFolder/upload.png\"}"
      end
    end
  end

  describe "wrong file type" do
    @tag authenticate: :staff
    test "upload file", %{conn: conn} do
      use_cassette "aws/list_assets#5" do
        conn =
          post(conn, build_url("upload"), %{
            "upload" => build_upload("test/fixtures/upload.pdf"),
            "details" => "{\"folderName\" : \"testFolder\"}"
          })

        assert response(conn, 400) =~ "Invalid file type"
      end
    end
  end

  defp build_url, do: "/v1/assets/"
  defp build_url(url), do: "#{build_url()}/#{url}"

  def build_upload(path, content_type \\ "image\png") do
    %Plug.Upload{path: path, filename: Path.basename(path), content_type: content_type}
  end
end
