defmodule CadetWeb.GradingControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.GradingController

  test "swagger" do
    GradingController.swagger_definitions()
    GradingController.swagger_path_index(nil)
    GradingController.swagger_path_show(nil)
    GradingController.swagger_path_update(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/")
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  @tag authenticate: :student
  describe "GET /, student" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/")
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  @tag authenticate: :staff
  describe "GET /, staff" do
    test "successful", %{conn: conn} do
      grader = conn.assigns[:current_user]
      group = insert(:group, %{leader_id: grader.id, leader: grader})
      students = insert_list(5, :student, %{group: group})
      mission = insert(:assessment, %{title: "mission", type: :mission, is_published: true})

      questions =
        insert_list(3, :question, %{
          type: :programming,
          question: build(:programming_question),
          assessment: mission,
          max_xp: 200
        })

      submissions =
        students
        |> Enum.take(2)
        |> Enum.map(&insert(:submission, %{assessment: mission, student: &1}))

      Enum.each(submissions, fn submission ->
        Enum.each(questions, fn question ->
          insert(:answer, %{
            xp: 200,
            question: question,
            submission: submission,
            answer: build(:programming_answer)
          })
        end)
      end)

      conn = get(conn, "/v1/grading/")

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "xp" => 600,
            "submissionId" => submission.id,
            "student" => %{
              "name" => submission.student.name,
              "id" => submission.student.id
            },
            "assessment" => %{
              "type" => "mission",
              "max_xp" => 600,
              "id" => mission.id
            }
          }
        end)

      assert ^expected = Enum.sort_by(json_response(conn, 200), & &1["submissionId"])
    end
  end

  @tag authenticate: :admin
  describe "GET /, admin" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/")
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end
end
