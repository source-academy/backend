defmodule CadetWeb.StoriesControllerTest do
  use CadetWeb.ConnCase
  use Timex

  alias Cadet.Stories.Story
  alias CadetWeb.StoriesController

  test "swagger" do
    StoriesController.swagger_definitions()
    StoriesController.swagger_path_index(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "ok request" do
    @tag authenticate: :student
    test "index file", %{conn: conn} do
      conn = get(conn, build_url(), %{})

      assert json_response(conn, 200) === []
    end
  end

  defp build_url, do: "/v1/stories/"
end
