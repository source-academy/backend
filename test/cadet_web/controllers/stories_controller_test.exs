defmodule CadetWeb.StoriesControllerTest do
  use CadetWeb.ConnCase
  use Timex

  alias Cadet.Stories.Story
  alias CadetWeb.StoriesController

  test "swagger" do
    StoriesController.swagger_definitions()
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  defp build_url, do: "/v1/stories/"
end
