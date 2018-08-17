defmodule CadetWeb.GradingControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.Assessments.Answer
  alias Cadet.Repo
  alias CadetWeb.GradingController

  test "swagger" do
    GradingController.swagger_definitions()
    GradingController.swagger_path_index(nil)
    GradingController.swagger_path_show(nil)
    GradingController.swagger_path_update(nil)
  end

  describe "GET /, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /:submissionid, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "POST /:submissionid/:questionid, unauthenticated" do
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 401) =~ "Unauthorised"
    end
  end

  describe "GET /, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "GET /:submissionid, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "POST /:submissionid/:questionid, student" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{"grading" => %{}})
      assert response(conn, 401) =~ "User is not permitted to grade."
    end

    @tag authenticate: :student
    test "missing parameter", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end
  end

  describe "GET /, staff" do
    @tag authenticate: :staff
    test "avenger gets his students submissions", %{conn: conn} do
      %{
        mission: mission,
        submissions: submissions
      } = seed_db(conn)

      conn = get(conn, build_url())

      expected =
        Enum.map(submissions, fn submission ->
          %{
            "grade" => 600,
            "adjustment" => -300,
            "id" => submission.id,
            "student" => %{
              "name" => submission.student.name,
              "id" => submission.student.id
            },
            "assessment" => %{
              "type" => "mission",
              "maxGrade" => 600,
              "id" => mission.id,
              "title" => mission.title,
              "coverImage" => Cadet.Assessments.Image.url({mission.cover_picture, mission})
            }
          }
        end)

      assert expected == Enum.sort_by(json_response(conn, 200), & &1["id"])
    end

    @tag authenticate: :staff
    test "pure mentor gets an empty list", %{conn: conn} do
      %{mentor: mentor} = seed_db(conn)

      conn =
        conn
        |> sign_in(mentor)
        |> get(build_url())

      assert json_response(conn, 200) == []
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

      conn = get(conn, build_url(submission.id))

      expected =
        answers
        |> Enum.filter(&(&1.submission.id == submission.id))
        |> Enum.sort_by(& &1.question.display_order)
        |> Enum.map(
          &%{
            "question" => %{
              "solutionTemplate" => &1.question.question.solution_template,
              "type" => "#{&1.question.type}",
              "id" => &1.question.id,
              "library" => %{
                "chapter" => &1.question.library.chapter,
                "globals" => &1.question.library.globals,
                "external" => %{
                  "name" => "#{&1.question.library.external.name}",
                  "symbols" => &1.question.library.external.symbols
                }
              },
              "content" => &1.question.question.content,
              "answer" => &1.answer.code
            },
            "maxGrade" => &1.question.max_grade,
            "grade" => %{
              "grade" => &1.grade,
              "adjustment" => &1.adjustment,
              "comment" => &1.comment
            }
          }
        )

      assert expected == json_response(conn, 200)
    end

    @tag authenticate: :staff
    test "pure mentor gets an empty list", %{conn: conn} do
      %{mentor: mentor} = seed_db(conn)

      conn =
        conn
        |> sign_in(mentor)
        |> get(build_url())

      assert json_response(conn, 200) == []
    end
  end

  describe "POST /:submissionid/:questionid, staff" do
    @tag authenticate: :staff
    test "successful", %{conn: conn} do
      %{answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        post(conn, build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{"adjustment" => -10, "comment" => "Never gonna give you up"}
        })

      assert response(conn, 200) == "OK"
      assert %{adjustment: -10, comment: "Never gonna give you up"} = Repo.get(Answer, answer.id)
    end

    @tag authenticate: :staff
    test "invalid param fails", %{conn: conn} do
      %{answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        post(conn, build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{"adjustment" => -9_999_999_999}
        })

      assert response(conn, 400) == "adjustment should not make total point < 0"
    end

    @tag authenticate: :staff
    test "staff who isn't the grader of said answer fails", %{conn: conn} do
      %{mentor: mentor, answers: answers} = seed_db(conn)

      answer = List.first(answers)

      conn =
        conn
        |> sign_in(mentor)
        |> post(build_url(answer.submission.id, answer.question.id), %{
          "grading" => %{"adjustment" => -100}
        })

      assert response(conn, 400) == "Answer not found or user not permitted to grade."
    end

    @tag authenticate: :staff
    test "missing parameter", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end
  end

  describe "GET /, admin" do
    @tag authenticate: :admin
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url())
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "GET /:submissionid, admin" do
    @tag authenticate: :student
    test "unauthorized", %{conn: conn} do
      conn = get(conn, build_url(1))
      assert response(conn, 401) =~ "User is not permitted to grade."
    end
  end

  describe "POST /:submissionid/:questionid, admin" do
    @tag authenticate: :admin
    test "unauthorized", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{"grading" => %{}})
      assert response(conn, 401) =~ "User is not permitted to grade."
    end

    @tag authenticate: :admin
    test "missing parameter", %{conn: conn} do
      conn = post(conn, build_url(1, 3), %{})
      assert response(conn, 400) =~ "Missing parameter"
    end
  end

  defp build_url, do: "/v1/grading/"
  defp build_url(submission_id), do: "#{build_url()}#{submission_id}/"
  defp build_url(submission_id, question_id), do: "#{build_url(submission_id)}#{question_id}"

  defp seed_db(conn) do
    grader = conn.assigns[:current_user]
    mentor = insert(:user, role: :staff)

    group =
      insert(:group, %{leader_id: grader.id, leader: grader, mentor_id: mentor.id, mentor: mentor})

    students = insert_list(5, :student, %{group: group})
    mission = insert(:assessment, %{title: "mission", type: :mission, is_published: true})

    questions =
      for index <- 1..3 do
        # insert with display order in reverse
        insert(:programming_question, %{
          assessment: mission,
          max_grade: 200,
          display_order: 4 - index
        })
      end

    submissions =
      students
      |> Enum.take(2)
      |> Enum.map(&insert(:submission, %{assessment: mission, student: &1}))

    answers =
      for submission <- submissions,
          question <- questions do
        insert(:answer, %{
          grade: 200,
          adjustment: -100,
          question: question,
          submission: submission,
          answer: build(:programming_answer)
        })
      end

    %{
      grader: grader,
      mentor: mentor,
      group: group,
      students: students,
      mission: mission,
      questions: questions,
      submissions: submissions,
      answers: answers
    }
  end
end
