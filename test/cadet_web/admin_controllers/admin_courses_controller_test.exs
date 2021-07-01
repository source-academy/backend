defmodule CadetWeb.AdminCoursesControllerTest do
  use CadetWeb.ConnCase

  import Cadet.SharedHelper

  alias Cadet.Repo
  alias Cadet.Courses
  alias Cadet.Courses.Course
  alias CadetWeb.AdminCoursesController

  test "swagger" do
    AdminCoursesController.swagger_definitions()
    AdminCoursesController.swagger_path_update_course_config(nil)
    AdminCoursesController.swagger_path_update_assessment_configs(nil)
  end

  describe "PUT /v2/courses/{course_id}/admin/config" do
    @tag authenticate: :admin
    test "succeeds 1", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      old_course = to_map(Repo.get(Course, course_id))

      params = %{
        "sourceChapter" => 2,
        "sourceVariant" => "lazy"
      }

      resp = put(conn, build_url_course_config(course_id), params)

      assert response(resp, 200) == "OK"
      updated_course = to_map(Repo.get(Course, course_id))
      refute old_course == updated_course
      assert update_map(old_course, params) == updated_course
    end

    @tag authenticate: :admin
    test "succeeds 2", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      old_course = to_map(Repo.get(Course, course_id))

      params = %{
        "courseName" => "Data Structures and Algorithms",
        "courseShortName" => "CS2040S",
        "enableGame" => false,
        "enableAchievements" => false,
        "enableSourcecast" => true,
        "sourceChapter" => 1,
        "sourceVariant" => "default",
        "moduleHelpText" => "help"
      }

      resp = put(conn, build_url_course_config(course_id), params)

      assert response(resp, 200) == "OK"
      updated_course = to_map(Repo.get(Course, course_id))
      refute old_course == updated_course
      assert update_map(old_course, params) == updated_course
    end

    @tag authenticate: :admin
    test "succeeds 3", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      old_course = to_map(Repo.get(Course, course_id))

      params = %{
        "courseName" => "Data Structures and Algorithms",
        "courseShortName" => "CS2040S",
        "enableGame" => false,
        "enableAchievements" => false,
        "enableSourcecast" => true,
        "moduleHelpText" => "help"
      }

      resp = put(conn, build_url_course_config(course_id), params)

      assert response(resp, 200) == "OK"
      updated_course = to_map(Repo.get(Course, course_id))
      refute old_course == updated_course
      assert update_map(old_course, params) == updated_course
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      old_course = Repo.get(Course, course_id)

      conn =
        put(conn, build_url_course_config(course_id), %{
          "sourceChapter" => 3,
          "sourceVariant" => "concurrent"
        })

      same_course = Repo.get(Course, course_id)

      assert response(conn, 403) == "Forbidden"
      assert old_course == same_course
    end

    @tag authenticate: :staff
    test "rejects requests if user does not belong to the specified course", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_course_config(course_id + 1), %{
          "sourceChapter" => 3,
          "sourceVariant" => "concurrent"
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_course_config(course_id), %{
          "sourceChapter" => 4,
          "sourceVariant" => "wasm"
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_course_config(course_id), %{
          "courseName" => "Data Structures and Algorithms",
          "courseShortName" => "CS2040S",
          "enableGame" => false,
          "enableAchievements" => false,
          "enableSourcecast" => true,
          "moduleHelpText" => "help",
          "sourceVariant" => "default"
        })

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  describe "GET /v2/courses/{course_id}/admin/configs/assessment_configs" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      config1 = insert(:assessment_config, %{order: 1, type: "Mission1", course: course})
      config3 = insert(:assessment_config, %{order: 3, type: "Mission3", course: course})

      config2 =
        insert(:assessment_config, %{
          build_solution: true,
          order: 2,
          type: "Mission2",
          course: course
        })

      resp =
        conn
        |> get(build_url_assessment_configs(course_id))
        |> json_response(200)

      expected = [
        %{
          "earlySubmissionXp" => 200,
          "hoursBeforeEarlyXpDecay" => 48,
          "buildSolution" => false,
          "buildHidden" => false,
          "isContest" => false,
          "type" => "Mission1",
          "AssessmentConfigId" => config1.id
        },
        %{
          "earlySubmissionXp" => 200,
          "hoursBeforeEarlyXpDecay" => 48,
          "buildSolution" => true,
          "buildHidden" => false,
          "isContest" => false,
          "type" => "Mission2",
          "AssessmentConfigId" => config2.id
        },
        %{
          "earlySubmissionXp" => 200,
          "hoursBeforeEarlyXpDecay" => 48,
          "buildSolution" => false,
          "buildHidden" => false,
          "isContest" => false,
          "type" => "Mission3",
          "AssessmentConfigId" => config3.id
        }
      ]

      assert expected == resp
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      resp = get(conn, build_url_assessment_configs(course_id))

      assert response(resp, 403) == "Forbidden"
    end
  end

  describe "PUT /v2/courses/{course_id}/admin/config/assessment_configs" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      config = insert(:assessment_config, %{course: Repo.get(Course, course_id)})

      old_configs = course_id |> Courses.get_assessment_configs() |> Enum.map(& &1.type)

      params = %{
        "assessmentConfigs" => [
          %{
            "AssessmentConfigId" => config.id,
            "courseId" => course_id,
            "type" => "Missions",
            "earlySubmissionXp" => 100,
            "hoursBeforeEarlyXpDecay" => 24,
            "decayRatePointsPerHour" => 1
          },
          %{
            "AssessmentConfigId" => -1,
            "courseId" => course_id,
            "type" => "Paths",
            "earlySubmissionXp" => 100,
            "hoursBeforeEarlyXpDecay" => 24,
            "decayRatePointsPerHour" => 1
          }
        ]
      }

      resp =
        conn
        |> put(build_url_assessment_configs(course_id), params)
        |> response(200)

      assert resp == "OK"

      new_configs = course_id |> Courses.get_assessment_configs() |> Enum.map(& &1.type)
      refute old_configs == new_configs
      assert new_configs == ["Missions", "Paths"]
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_configs(course_id), %{
          "assessmentConfigs" => []
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects request if user is not in specified course", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_configs(course_id + 1), %{
          "assessmentConfigs" => []
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params 1", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_configs(course_id), %{
          "assessmentConfigs" => "Missions"
        })

      assert response(conn, 400) == "Missing List parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params 2", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_configs(course_id), %{
          "assessmentConfigs" => [1, "Missions", "Quests"]
        })

      assert response(conn, 400) == "List parameter does not contain all maps"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = put(conn, build_url_assessment_configs(course_id), %{})

      assert response(conn, 400) == "Missing List parameter(s)"
    end
  end

  describe "DELETE /v2/courses/{course_id}/admin/config/assessment_config" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      config1 = insert(:assessment_config, %{order: 1, course: course, type: "Missions"})
      _config2 = insert(:assessment_config, %{order: 2, course: course, type: "Paths"})

      old_configs = course_id |> Courses.get_assessment_configs() |> Enum.map(& &1.type)

      params = %{
        "assessmentConfig" => %{
          "AssessmentConfigId" => config1.id,
          "courseId" => course_id,
          "type" => "Missions",
          "earlySubmissionXp" => 100,
          "hoursBeforeEarlyXpDecay" => 24,
          "decayRatePointsPerHour" => 1
        }
      }

      resp =
        conn
        |> delete(build_url_assessment_config(course_id), params)
        |> response(200)

      assert resp == "OK"

      new_configs = course_id |> Courses.get_assessment_configs() |> Enum.map(& &1.type)
      refute old_configs == new_configs
      assert new_configs == ["Paths"]
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        delete(conn, build_url_assessment_config(course_id), %{
          "assessmentConfig" => %{}
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects request if user is not in specified course", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        delete(conn, build_url_assessment_config(course_id + 1), %{
          "assessmentConfig" => %{}
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params 1", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        delete(conn, build_url_assessment_config(course_id), %{
          "assessmentConfigs" => "Missions"
        })

      assert response(conn, 400) == "Missing Map parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = delete(conn, build_url_assessment_config(course_id), %{})

      assert response(conn, 400) == "Missing Map parameter(s)"
    end
  end

  defp build_url_course_config(course_id), do: "/v2/courses/#{course_id}/admin/config"

  defp build_url_assessment_configs(course_id),
    do: "/v2/courses/#{course_id}/admin/config/assessment_configs"

  defp build_url_assessment_config(course_id),
    do: "/v2/courses/#{course_id}/admin/config/assessment_config"

  defp to_map(schema), do: schema |> Map.from_struct() |> Map.drop([:updated_at])

  defp update_map(map1, params),
    do: Map.merge(map1, to_snake_case_atom_keys(params), fn _k, _v1, v2 -> v2 end)
end
