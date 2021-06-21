defmodule CadetWeb.CoursesControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Repo
  alias Cadet.Courses.Course
  alias CadetWeb.CoursesController

  test "swagger" do
    CoursesController.swagger_definitions()
    CoursesController.swagger_path_get_course_config(nil)
  end

  describe "GET /v2/courses/course_id/config, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url_config(course.id))
      assert response(conn, 401) == "Unauthorised"
    end
  end

  describe "GET /v2/courses/course_id/config" do
    @tag authenticate: :student
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)

      insert(:assessment_config, %{order: 3, type: "Paths", course: course})
      insert(:assessment_config, %{order: 1, type: "Missions", course: course})
      insert(:assessment_config, %{order: 2, type: "Quests", course: course})

      resp = conn |> get(build_url_config(course_id)) |> json_response(200)

      assert %{
               "config" => %{
                 "courseName" => "Programming Methodology",
                 "courseShortName" => "CS1101S",
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

  defp build_url_config(course_id), do: "/v2/courses/#{course_id}/config"
end
