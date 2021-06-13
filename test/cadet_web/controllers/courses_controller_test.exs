defmodule CadetWeb.CoursesControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.CoursesController

  test "swagger" do
    CoursesController.swagger_definitions()
    CoursesController.swagger_path_get_course_config(nil)
  end

  describe "GET /v2/course/course_id/config, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url_config(course.id))
      assert response(conn, 401) == "Unauthorised"
    end
  end

  describe "GET /v2/course/course_id/config" do
    @tag authenticate: :student
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      insert(:assessment_types, %{order: 1, type: "Missions", course_id: course_id})
      insert(:assessment_types, %{order: 2, type: "Quests", course_id: course_id})
      insert(:assessment_types, %{order: 3, type: "Paths", course_id: course_id})

      resp = conn |> get(build_url_config(course_id)) |> json_response(200)

      assert %{
               "config" => %{
                 "moduleName" => "Programming Methodology",
                 "moduleCode" => "CS1101S",
                 "viewable" => true,
                 "enableGame" => true,
                 "enableAchievements" => true,
                 "enableSourcecast" => true,
                 "sourceChapter" => 1,
                 "sourceVariant" => "default",
                 "moduleHelpText" => "Help Text",
                 "assessmentTypes" => ["Missions", "Quests", "Paths"]
               }
             } = resp
    end

    @tag authenticate: :student
    test "returns with error for user not belonging to the specified course", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        conn
        |> get(build_url_config(course_id + 1))

      assert response(conn, 403) == "Forbidden"
    end
  end

  defp build_url_config(course_id), do: "/v2/course/#{course_id}/config"
end
