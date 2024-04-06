defmodule CadetWeb.TeamsControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Repo
  alias Cadet.Courses.Course
  alias CadetWeb.TeamController

  setup do
    Cadet.Test.Seeds.assessments()
  end

  test "swagger" do
    TeamController.swagger_path_index(nil)
  end

  describe "GET /v2/admin/teams" do
    @tag authenticate: :student
    test "unauthorized with student", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url_get(course.id))
      assert response(conn, 403) == "Forbidden"
    end

    @tag authenticate: :admin
    test "authorized with zero team", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      # assessment = insert(:assessment, %{course: course})
      conn = get(conn, build_url_get(course.id))
      assert response(conn, 200) == "[]"
    end

    @tag authenticate: :admin
    test "authorized with multiple teams", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course})
      team = insert(:team, %{assessment: assessment})
      conn = get(conn, build_url_get(course.id))

      team_formation_overview = %{
        teamId: team.id,
        assessmentId: assessment.id,
        assessmentName: assessment.title,
        assessmentType: assessment.config.type,
        studentIds: [],
        studentNames: []
      }

      assert response(conn, 200) == "[#{Jason.encode!(team_formation_overview)}]"
    end
  end

  describe "GET /v2/courses/:course_id/team/:assessment_id" do
    @tag authenticate: :admin
    test "team not found", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course})
      conn = get(conn, build_url_get_by_assessment(course.id, assessment.id))
      assert response(conn, 404) == "Team is not found!"
    end

    @tag authenticate: :admin
    test "team(s) found", %{conn: conn} do
      course_id = conn.assigns[:course_id]
      course = Repo.get(Course, course_id)
      cr = conn.assigns[:test_cr]
      cr1 = insert(:course_registration, %{course: course, role: :student})
      cr2 = insert(:course_registration, %{course: course, role: :student})
      assessment = insert(:assessment, %{course: course})
      teammember1 = insert(:team_member, %{student: cr1})
      teammember2 = insert(:team_member, %{student: cr2})
      teammember3 = insert(:team_member, %{student: cr})

      team =
        insert(:team, %{
          assessment: assessment,
          team_members: [teammember1, teammember2, teammember3]
        })

      conn = get(conn, build_url_get_by_assessment(course.id, assessment.id))

      team_formation_overview = %{
        teamId: team.id,
        assessmentId: assessment.id,
        assessmentName: assessment.title,
        assessmentType: assessment.config.type,
        studentIds: [cr1.user.id, cr2.user.id, cr.user.id],
        studentNames: [cr1.user.name, cr2.user.name, cr.user.name]
      }

      assert response(conn, 200) == "#{Jason.encode!(team_formation_overview)}"
    end
  end

  defp build_url_get(course_id), do: "/v2/courses/#{course_id}/admin/teams"

  defp build_url_get_by_assessment(course_id, assessment_id),
    do: "/v2/courses/#{course_id}/team/#{assessment_id}"
end
