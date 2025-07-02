defmodule CadetWeb.AdminTeamsControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Repo
  alias Cadet.Courses.Course
  alias CadetWeb.AdminTeamsController

  test "swagger" do
    AdminTeamsController.swagger_definitions()
    AdminTeamsController.swagger_path_index(nil)
    AdminTeamsController.swagger_path_create(nil)
    AdminTeamsController.swagger_path_update(nil)
    AdminTeamsController.swagger_path_delete(nil)
  end

  describe "GET /admin/teams" do
    test "unauthenticated", %{conn: conn} do
      course = insert(:course)
      conn = get(conn, build_url(course.id))
      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = get(conn, build_url(course_id))
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "returns a list of teams for the specified course only", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      team1 = insert(:team, %{assessment: assessment})
      insert(:team_member, %{team: team1})
      insert(:team_member, %{team: team1})
      team2 = insert(:team, %{assessment: assessment})
      insert(:team_member, %{team: team2})
      insert(:team_member, %{team: team2})

      conn = get(conn, build_url(course_id))
      assert response(conn, 200)

      # Insert other random teams to test filtering
      other_course = insert(:course)
      other_assessment = insert(:assessment, %{course: other_course, max_team_size: 2})
      team3 = insert(:team, %{assessment: other_assessment})
      insert(:team_member, %{team: team3})
      insert(:team_member, %{team: team3})

      response_body =
        conn.resp_body
        |> Jason.decode!()
        # Sort the teams by teamId for consistent testing
        |> Enum.sort_by(& &1["teamId"])

      assert is_list(response_body)
      assert length(response_body) == 2
      assert response_body |> hd() |> Map.get("teamId") == team1.id
      assert response_body |> hd() |> Map.get("assessmentId") == assessment.id
      assert response_body |> tl() |> hd() |> Map.get("teamId") == team2.id
      assert response_body |> tl() |> hd() |> Map.get("assessmentId") == assessment.id
    end
  end

  describe "POST /admin/teams" do
    test "unauthenticated", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course = insert(:course)
      conn = post(conn, build_url(course.id), %{})
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "creates a new team", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      student1 = insert(:course_registration, %{course: course})
      student2 = insert(:course_registration, %{course: course})

      team_params = %{
        "team" => %{
          "assessment_id" => assessment.id,
          "student_ids" => [[%{userId: student1.id}, %{userId: student2.id}]]
        }
      }

      conn = post(conn, build_url(course_id), team_params)
      assert response(conn, 201) =~ "Teams created successfully."
    end

    @tag authenticate: :staff
    test "creates an invalid team with duplicate members", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      student1 = insert(:course_registration, %{course: course})

      team_params = %{
        "team" => %{
          "assessment_id" => assessment.id,
          "student_ids" => [[%{userId: student1.id}, %{userId: student1.id}]]
        }
      }

      conn = post(conn, build_url(course_id), team_params)
      assert response(conn, 409) =~ "One or more students appear multiple times in a team!"
    end

    @tag authenticate: :staff
    test "creates an invalid team which exceeds max team size", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      student1 = insert(:course_registration, %{course: course})
      student2 = insert(:course_registration, %{course: course})
      student3 = insert(:course_registration, %{course: course})

      team_params = %{
        "team" => %{
          "assessment_id" => assessment.id,
          "student_ids" => [
            [%{userId: student1.id}, %{userId: student2.id}, %{userId: student3.id}]
          ]
        }
      }

      conn = post(conn, build_url(course_id), team_params)
      assert response(conn, 409) =~ "One or more teams exceed the maximum team size!"
    end

    @tag authenticate: :staff
    test "creates an invalid team where student not enrolled in course", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      student1 = insert(:course_registration, %{course: course})
      student2 = insert(:course_registration)

      team_params = %{
        "team" => %{
          "assessment_id" => assessment.id,
          "student_ids" => [[%{userId: student1.id}, %{userId: student2.id}]]
        }
      }

      conn = post(conn, build_url(course_id), team_params)
      assert response(conn, 409) =~ "One or more students not enrolled in this course!"
    end

    @tag authenticate: :staff
    test "creates an invalid team where student already has a team for this assessment", %{
      conn: conn
    } do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      student1 = insert(:course_registration, %{course: course})
      student2 = insert(:course_registration, %{course: course})
      student3 = insert(:course_registration, %{course: course})
      team = insert(:team, %{assessment: assessment})
      insert(:team_member, %{team: team, student: student1})
      insert(:team_member, %{team: team, student: student2})

      team_params = %{
        "team" => %{
          "assessment_id" => assessment.id,
          "student_ids" => [[%{userId: student1.id}, %{userId: student3.id}]]
        }
      }

      conn = post(conn, build_url(course_id), team_params)
      assert response(conn, 409) =~ "One or more students already in a team for this assessment!"
    end
  end

  describe "PUT /admin/teams/{teamId}" do
    test "unauthenticated", %{conn: conn} do
      course = insert(:course)
      conn = put(conn, build_url(course.id, 1), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course = insert(:course)
      conn = put(conn, build_url(course.id, 1), %{})
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "updates a team", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      student1 = insert(:course_registration, %{course: course})
      student2 = insert(:course_registration, %{course: course})
      student3 = insert(:course_registration, %{course: course})
      team = insert(:team, %{assessment: assessment})
      insert(:team_member, %{team: team, student: student1})
      insert(:team_member, %{team: team, student: student2})
      insert(:team_member, %{team: team, student: student3})

      updated_team_params = %{
        "course_id" => course.id,
        "teamId" => team.id,
        "assessmentId" => assessment.id,
        "student_ids" => [[%{userId: student1.id}, %{userId: student3.id}]]
      }

      conn = put(conn, build_url(course_id, team.id), updated_team_params)
      assert response(conn, 200) =~ "Teams updated successfully."
    end

    @tag authenticate: :staff
    test "updates a team which exceeds max team size", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      assessment = insert(:assessment, %{course: course, max_team_size: 2})
      student1 = insert(:course_registration, %{course: course})
      student2 = insert(:course_registration, %{course: course})
      student3 = insert(:course_registration, %{course: course})
      team1 = insert(:team, %{assessment: assessment})
      insert(:team_member, %{team: team1, student: student1})
      insert(:team_member, %{team: team1, student: student2})
      team2 = insert(:team, %{assessment: assessment})

      updated_team_params = %{
        "course_id" => course.id,
        "teamId" => team2.id,
        "assessmentId" => assessment.id,
        "student_ids" => [[%{userId: student1.id}, %{userId: student3.id}]]
      }

      conn = put(conn, build_url(course_id, team2.id), updated_team_params)

      assert response(conn, 409) =~
               "One or more students are already in another team for the same assessment!"
    end
  end

  describe "DELETE /admin/teams/{teamId}" do
    test "unauthenticated", %{conn: conn} do
      course = insert(:course)
      team = insert(:team)
      conn = delete(conn, build_url(course.id, team.id))
      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "Forbidden", %{conn: conn} do
      course = insert(:course)
      team = insert(:team)
      conn = delete(conn, build_url(course.id, team.id))
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "deletes a team", %{conn: conn} do
      course_id = conn.assigns.course_id
      team = insert(:team)
      conn = delete(conn, build_url(course_id, team.id))
      assert response(conn, 200) =~ "Team deleted successfully."
    end

    @tag authenticate: :staff
    test "delete a team that does not exist", %{conn: conn} do
      course_id = conn.assigns.course_id
      conn = delete(conn, build_url(course_id, -1))
      assert response(conn, 404) =~ "Team not found!"
    end

    @tag authenticate: :staff
    test "delete a team that has already submitted answers", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get(Course, course_id)
      config = insert(:assessment_config, %{course: course})

      assessment =
        insert(:assessment, %{
          is_published: true,
          course: course,
          config: config,
          max_team_size: 2
        })

      student1 = insert(:course_registration, %{course: course})
      student2 = insert(:course_registration, %{course: course})
      team = insert(:team, %{assessment: assessment})
      insert(:team_member, %{team: team, student: student1})
      insert(:team_member, %{team: team, student: student2})

      insert(:submission, %{
        assessment: assessment,
        team: team,
        student: nil,
        status: :submitted
      })

      conn = delete(conn, build_url(course_id, team.id))

      assert response(conn, 409) =~
               "This team has submitted their answers! Unable to delete the team!"
    end
  end

  defp build_url(course_id), do: "/v2/courses/#{course_id}/admin/teams/"

  defp build_url(course_id, team_id),
    do: "#{build_url(course_id)}#{team_id}"
end
