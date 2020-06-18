defmodule CadetWeb.AssetsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AssetsController

  test "swagger" do
    AssetsController.swagger_path_index(nil)
    AssetsController.swagger_path_upload(nil)
    AssetsController.swagger_path_delete(nil)
  end

  setup do
    student = insert(:user, %{role: :student})
    staff = insert(:user, %{role: :staff})

    {
     :ok,
     %{student: student},
     %{staff: staff}
    }
  end

  describe "GET /assets/:folder_name, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url("random_folder"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /assets/upload, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url("upload"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "DELETE /assets/delete, unauthenticated" do
    test "unauthorised", %{conn: conn} do
      conn = delete(conn, build_url("delete"), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /assets/:foldername, forbidden" do
    @tag authenticate: :student
    test "student permission", %{conn: conn} do
      conn = get(conn, build_url("testFolder"), %{})
      assert response(conn, 401) =~ "User not allowed to upload assets"
    end
  end

  describe "GET /assets/:foldername, bad request" do
    @tag authenticate: :staff
    test "inaccessible folder", %{conn: conn} do
      conn = get(conn, build_url("wrong_folder"), %{})
      assert response(conn, 400) =~ "Bad Request"
    end
  end

  describe "GET /assets/:foldername, ok" do
    @tag authenticate: :staff
    test "good folder", %{conn: conn} do
      conn = get(conn, build_url("testFolder"), %{})
      assert response(conn, 200)
    end
  end


  defp build_url, do: "/v1/assets/"
  defp build_url(url), do: "#{build_url()}/#{url}"


end
