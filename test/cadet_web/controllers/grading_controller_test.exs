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

  describe "GET /:submissionid, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/1")
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/")
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "GET /:submissionid, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/1")
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "GET /, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

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

  describe "GET /:submissionid, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{
        submissions: submissions,
        answers: answers
      } = seed_db(conn)

      submission = List.first(submissions)

      conn = get(conn, "/v1/grading/#{submission.id}")

      expected =
        answers
        |> Enum.filter(&(&1.submission.id == submission.id))
        |> Enum.map(
          &%{
            "question" => %{
              "solution_template" => &1.question.question.solution_template,
              "questionType" => "#{&1.question.type}",
              "questionId" => &1.question.id,
              "library" => &1.question.library,
              "content" => &1.question.question.content,
              "answer" => &1.answer.code
            },
            "max_xp" => &1.question.max_xp,
            "grade" => %{
              "xp" => &1.xp,
              "adjustment" => &1.adjustment,
              "comment" => &1.comment
            }
          }
        )

      assert ^expected = Enum.sort_by(json_response(conn, 200), & &1["question"]["questionId"])
    end
  end

  describe "GET /, admin" do
    @tag authenticate: :admin
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/")
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "GET /:submissionid, admin" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, "/v1/grading/1")
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  defp seed_db(conn) do
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

    answers =
      Enum.flat_map(submissions, fn submission ->
        Enum.map(questions, fn question ->
          insert(:answer, %{
            xp: 200,
            question: question,
            submission: submission,
            answer: build(:programming_answer)
          })
        end)
      end)

    %{
      grader: grader,
      group: group,
      students: students,
      mission: mission,
      questions: questions,
      submissions: submissions,
      answers: answers
    }
  end
end
