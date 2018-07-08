defmodule CadetWeb.GradingControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.GradingController

  test "swagger" do
    GradingController.swagger_definitions()
    GradingController.swagger_path_index(nil)
    GradingController.swagger_path_show(nil)
    GradingController.swagger_path_update(nil)
  end

  # Unauthenticated user
  describe "GET /, Unauthenticated" do
    test "is disallowed", %{conn: conn} do
      conn = get(conn, "/v1/grading")

      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  @tag authenticate: :student
  describe "GET /, :student" do
    test "is disallowed", %{conn: conn} do
      conn = get(conn, "/v1/grading")

      assert response(conn, 401) =~ "User is not permitted to grade submissions"
    end
  end

  @tag authenticate: :staff
  describe "GET /, :staff" do
    test "successful", %{conn: conn} do
      user = conn.assigns[:current_user]
      student = insert(:user)
      assessment = insert(:assessment)

      submission =
        insert(
          :submission,
          grader_id: user.id,
          student_id: student.id,
          assessment_id: assessment.id
        )

      answers = insert_list(3, :answer, submission_id: submission.id)
      xp = answers |> Enum.map(& &1.xp) |> Enum.reduce(&(&1 + &2))

      conn = get(conn, "/v1/grading")

      body = json_response(conn, 200)

      expected = [
        %{
          "xp" => xp,
          "submissionId" => submission.id,
          "student" => %{"id" => student.id, "name" => student.name},
          "graded" => submission.status == :graded,
          "assessment" => %{
            "type" => "#{assessment.category}",
            "max_xp" => assessment.max_xp,
            "id" => assessment.id
          }
        }
      ]

      assert ^expected = body
    end
  end
end
