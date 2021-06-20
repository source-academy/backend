defmodule CadetWeb.AdminCoursesControllerTest do
  use CadetWeb.ConnCase

  import Cadet.SharedHelper
  import Ecto.Query
  alias Cadet.Repo
  alias Cadet.Courses.{Course, AssessmentConfig, AssessmentType}
  alias CadetWeb.AdminCoursesController

  test "swagger" do
    AdminCoursesController.swagger_definitions()
    AdminCoursesController.swagger_path_update_course_config(nil)
    AdminCoursesController.swagger_path_update_assessment_config(nil)
    AdminCoursesController.swagger_path_update_assessment_types(nil)
  end

  describe "PUT /v2/course/{course_id}/admin/course_config" do
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

  describe "GET /v2/course/{course_id}/admin/assessment_configs" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)

      type1 = insert(:assessment_type, %{order: 1, type: "Mission1", course: course})
      insert(:assessment_config, %{assessment_type: type1})

      type3 = insert(:assessment_type, %{order: 3, type: "Mission3", course: course})
      insert(:assessment_config, %{assessment_type: type3})

      type2 = insert(:assessment_type, %{is_graded: false, order: 2, type: "Mission2", course: course})
      insert(:assessment_config, %{assessment_type: type2})

      resp =
        conn
        |> get(build_url_assessment_config(course_id) <> "s")
        |> json_response(200)

      expected = [
        %{
          "decayRatePointsPerHour" => 1,
          "earlySubmissionXp" => 200,
          "hoursBeforeEarlyXpDecay" => 48,
          "isGraded" => true,
          "order" => 1,
          "type" => "Mission1"
        },
        %{
          "decayRatePointsPerHour" => 1,
          "earlySubmissionXp" => 200,
          "hoursBeforeEarlyXpDecay" => 48,
          "isGraded" => false,
          "order" => 2,
          "type" => "Mission2"
        },
        %{
          "decayRatePointsPerHour" => 1,
          "earlySubmissionXp" => 200,
          "hoursBeforeEarlyXpDecay" => 48,
          "isGraded" => true,
          "order" => 3,
          "type" => "Mission3"
        }
      ]

      assert expected == resp
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      resp = get(conn, build_url_assessment_config(course_id) <> "s")

      assert response(resp, 403) == "Forbidden"
    end
  end

  describe "PUT /v2/course/{course_id}/admin/assessment_config" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      type = insert(:assessment_type, %{course: course, order: 2})
      old_config = insert(:assessment_config, %{assessment_type: type})

      params = %{
        "order" => type.order,
        "earlySubmissionXp" => 100,
        "hoursBeforeEarlyXpDecay" => 24,
        "decayRatePointsPerHour" => 2
      }

      resp = put(conn, build_url_assessment_config(course_id), params)

      assert response(resp, 200) == "OK"
      updated_config = Repo.get(AssessmentConfig, old_config.id)
      assert updated_config.decay_rate_points_per_hour == 2
      assert updated_config.early_submission_xp == 100
      assert updated_config.hours_before_early_xp_decay == 24
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      type = insert(:assessment_type, %{course: course})
      insert(:assessment_config, %{assessment_type: type})

      conn =
        put(conn, build_url_assessment_config(course_id), %{
          "order" => type.order,
          "earlySubmissionXp" => 100,
          "hoursBeforeEarlyXpDecay" => 24,
          "decayRatePointsPerHour" => 2
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects request if user does not belong to specified course", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      type = insert(:assessment_type, %{course: course})
      insert(:assessment_config, %{assessment_type: type})

      conn =
        put(conn, build_url_assessment_config(course_id + 1), %{
          "order" => type.order,
          "earlySubmissionXp" => 100,
          "hoursBeforeEarlyXpDecay" => 24,
          "decayRatePointsPerHour" => 2
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      type = insert(:assessment_type, %{course: course})
      insert(:assessment_config, %{assessment_type: type})

      conn =
        put(conn, build_url_assessment_config(course_id), %{
          "order" => type.order,
          "earlySubmissionXp" => 100,
          "hoursBeforeEarlyXpDecay" => -1,
          "decayRatePointsPerHour" => 200
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      type = insert(:assessment_type, %{course: course})
      insert(:assessment_config, %{assessment_type: type})

      conn =
        put(conn, build_url_assessment_config(course_id), %{
          "order" => type.order,
          "hoursBeforeEarlyXpDecay" => 24,
          "decayRatePointsPerHour" => 2
        })

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  describe "PUT /v2/course/{course_id}/admin/assessment_types" do
    @tag authenticate: :admin
    test "succeeds", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      insert(:assessment_type, %{course: Repo.get(Course, course_id)})

      old_course =
        Course
        |> where(id: ^course_id)
        |> join(:left, [c], at in assoc(c, :assessment_type))
        |> preload([c, at],
          assessment_type: ^from(at in AssessmentType, order_by: [asc: at.order])
        )
        |> Repo.all()
        |> hd()

      old_types = Enum.map(old_course.assessment_type, fn x -> x.type end)

      conn =
        put(conn, build_url_assessment_types(course_id), %{
          "assessmentTypes" => ["Missions", "Quests", "Contests"]
        })

      new_course =
        Course
        |> where(id: ^course_id)
        |> join(:left, [c], at in assoc(c, :assessment_type))
        |> preload([c, at],
          assessment_type: ^from(at in AssessmentType, order_by: [asc: at.order])
        )
        |> Repo.all()
        |> hd()

      new_types = Enum.map(new_course.assessment_type, fn x -> x.type end)

      assert response(conn, 200) == "OK"
      refute old_types == new_types
      assert new_types == ["Missions", "Quests", "Contests"]
    end

    @tag authenticate: :student
    test "rejects forbidden request for non-staff users", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_types(course_id), %{
          "assessmentTypes" => ["Missions", "Quests", "Contests"]
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects request if user is not in specified course", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_types(course_id + 1), %{
          "assessmentTypes" => ["Missions", "Quests", "Contests"]
        })

      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params 1", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_types(course_id), %{
          "assessmentTypes" => "Missions"
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with invalid params 2", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn =
        put(conn, build_url_assessment_types(course_id), %{
          "assessmentTypes" => [1, "Missions", "Quests"]
        })

      assert response(conn, 400) == "Invalid parameter(s)"
    end

    @tag authenticate: :staff
    test "rejects requests with missing params", %{conn: conn} do
      course_id = conn.assigns[:course_id]

      conn = put(conn, build_url_assessment_types(course_id), %{})

      assert response(conn, 400) == "Missing parameter(s)"
    end
  end

  defp build_url_course_config(course_id), do: "/v2/course/#{course_id}/admin/course_config"

  defp build_url_assessment_config(course_id),
    do: "/v2/course/#{course_id}/admin/assessment_config"

  defp build_url_assessment_types(course_id),
    do: "/v2/course/#{course_id}/admin/assessment_types"

  defp to_map(schema), do: Map.from_struct(schema) |> Map.drop([:updated_at])

  defp update_map(map1, params),
    do: Map.merge(map1, to_snake_case_atom_keys(params), fn _k, _v1, v2 -> v2 end)
end
