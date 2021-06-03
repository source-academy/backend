defmodule CadetWeb.CoursesControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.CoursesController

  test "swagger" do
    CoursesController.swagger_definitions()
    CoursesController.swagger_path_get_course_config(nil)
  end

  describe "GET /courses/course_id/config, unauthenticated" do
    test "unathorized", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url_config(course.id))
      assert response(conn, 401) == "Unauthorised"
    end
  end

  describe "GET /courses/course_id/config" do
    @tag authenticate: :student
    test "succeeds", %{conn: conn} do
      course = insert(:course)
      resp = conn |> get(build_url_config(course.id)) |> json_response(200)

      assert %{
               "config" => %{
                 "name" => "Programming Methodology",
                 "module_code" => "CS1101S",
                 "viewable" => true,
                 "enable_game" => true,
                 "enable_achievements" => true,
                 "enable_sourcecast" => true,
                 "source_chapter" => 1,
                 "source_variant" => "default",
                 "module_help_text" => "Help Text"
               }
             } = resp
    end

    @tag authenticate: :student
    test "returns with error for invalid course id", %{conn: conn} do
      course = insert(:course)

      conn =
        conn
        |> get(build_url_config(course.id + 1))

      assert response(conn, 400) == "Invalid course id"
    end
  end

  defp build_url_config(course_id), do: "/v2/courses/#{course_id}/config"
end
