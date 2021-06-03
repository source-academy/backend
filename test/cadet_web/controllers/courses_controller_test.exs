defmodule CadetWeb.CoursesControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.CoursesController

  test "swagger" do
    CoursesController.swagger_definitions()
    CoursesController.swagger_path_get_sublanguage(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url(course.id))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /courses/course_id/sublanguage" do
    @tag authenticate: :student
    test "succeeds", %{conn: conn} do
      course = insert(:course, %{source_chapter: 2, source_variant: "lazy"})

      resp = conn |> get(build_url(course.id)) |> json_response(200)

      assert %{"sublanguage" => %{"source_chapter" => 2, "source_variant" => "lazy"}} = resp
    end

    @tag authenticate: :student
    test "returns with error for invalid course id", %{conn: conn} do
      course = insert(:course)

      conn =
        conn
        |> get(build_url(course.id + 1))

      assert response(conn, 400) == "Invalid course id"
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/sublanguage"
end
