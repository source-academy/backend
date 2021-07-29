defmodule CadetWeb.CoursesControllerTest do
  use CadetWeb.ConnCase

  import Ecto.Query

  alias Cadet.Repo
  alias Cadet.Accounts.CourseRegistration
  alias Cadet.Courses.Course
  alias CadetWeb.CoursesController

  test "swagger" do
    CoursesController.swagger_definitions()
    CoursesController.swagger_path_get_course_config(nil)
  end

  describe "POST /v2/config/create" do
    @tag authenticate: :student
    test "succeeds", %{conn: conn} do
      user = conn.assigns.current_user
      assert CourseRegistration |> where(user_id: ^user.id) |> Repo.all() |> length() == 1

      params = %{
        "course_name" => "CS1101S Programming Methodology (AY20/21 Sem 1)",
        "course_short_name" => "CS1101S",
        "viewable" => "true",
        "enable_game" => "true",
        "enable_achievements" => "true",
        "enable_sourcecast" => "true",
        "source_chapter" => "1",
        "source_variant" => "default",
        "module_help_text" => "Help Text"
      }

      resp = post(conn, build_url_create(), params)

      assert response(resp, 200) == "OK"
      assert CourseRegistration |> where(user_id: ^user.id) |> Repo.all() |> length() == 2
    end

    @tag authenticate: :student
    test "fails when there are missing parameters", %{conn: conn} do
      user = conn.assigns.current_user
      assert CourseRegistration |> where(user_id: ^user.id) |> Repo.all() |> length() == 1

      params = %{
        "course_name" => "CS1101S Programming Methodology (AY20/21 Sem 1)",
        "course_short_name" => "CS1101S",
        "viewable" => "true",
        "enable_achievements" => "true",
        "enable_sourcecast" => "true",
        "source_variant" => "default",
        "module_help_text" => "Help Text"
      }

      conn = post(conn, build_url_create(), params)

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :student
    test "fails when there are invalid parameters", %{conn: conn} do
      user = conn.assigns.current_user
      assert CourseRegistration |> where(user_id: ^user.id) |> Repo.all() |> length() == 1

      params = %{
        "course_name" => "CS1101S Programming Methodology (AY20/21 Sem 1)",
        "course_short_name" => "CS1101S",
        "viewable" => "boolean",
        "enable_game" => "true",
        "enable_achievements" => "true",
        "enable_sourcecast" => "true",
        "source_chapter" => "1",
        "source_variant" => "default",
        "module_help_text" => "Help Text"
      }

      conn = post(conn, build_url_create(), params)

      assert response(conn, 400) == "Invalid parameter(s)"
    end
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

  defp build_url_create, do: "/v2/config/create"
  defp build_url_config(course_id), do: "/v2/courses/#{course_id}/config"
end
