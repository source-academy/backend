defmodule CadetWeb.AdminLLMStatsControllerTest do
  use CadetWeb.ConnCase

  alias Cadet.{LLMStats, Repo, Courses.Course}

  describe "GET /v2/courses/:course_id/admin/llm-stats/:assessment_id" do
    test "401 when not logged in", %{conn: conn} do
      course = insert(:course)
      assessment = insert(:assessment, course: course)

      conn = get(conn, assessment_stats_url(course.id, assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "403 for students", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get!(Course, course_id)
      assessment = insert(:assessment, course: course)

      conn = get(conn, assessment_stats_url(course_id, assessment.id))
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "returns assessment statistics with per-question breakdown", %{conn: conn} do
      %{assessment: assessment, question_1: question_1, question_2: question_2} =
        seed_usage_logs(conn)

      resp =
        conn
        |> get(assessment_stats_url(conn.assigns.course_id, assessment.id))
        |> json_response(200)

      assert resp["total_uses"] == 4
      assert resp["unique_submissions"] == 2
      assert resp["unique_users"] == 2

      assert [q1_stats, q2_stats] = resp["questions"]

      assert q1_stats["question_id"] == question_1.id
      assert q1_stats["display_order"] == question_1.display_order
      assert q1_stats["total_uses"] == 3
      assert q1_stats["unique_submissions"] == 2
      assert q1_stats["unique_users"] == 2

      assert q2_stats["question_id"] == question_2.id
      assert q2_stats["display_order"] == question_2.display_order
      assert q2_stats["total_uses"] == 1
      assert q2_stats["unique_submissions"] == 1
      assert q2_stats["unique_users"] == 1
    end
  end

  describe "GET /v2/courses/:course_id/admin/llm-stats/:assessment_id/:question_id" do
    test "401 when not logged in", %{conn: conn} do
      course = insert(:course)
      assessment = insert(:assessment, course: course)
      question = insert(:question, assessment: assessment, display_order: 1)

      conn = get(conn, question_stats_url(course.id, assessment.id, question.id))
      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "403 for students", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get!(Course, course_id)
      assessment = insert(:assessment, course: course)
      question = insert(:question, assessment: assessment, display_order: 1)

      conn = get(conn, question_stats_url(course_id, assessment.id, question.id))
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "returns question-level statistics", %{conn: conn} do
      %{assessment: assessment, question_1: question_1} = seed_usage_logs(conn)

      resp =
        conn
        |> get(question_stats_url(conn.assigns.course_id, assessment.id, question_1.id))
        |> json_response(200)

      assert resp == %{
               "total_uses" => 3,
               "unique_submissions" => 2,
               "unique_users" => 2
             }
    end
  end

  describe "GET /v2/courses/:course_id/admin/llm-stats/:assessment_id/feedback" do
    test "401 when not logged in", %{conn: conn} do
      course = insert(:course)
      assessment = insert(:assessment, course: course)

      conn = get(conn, feedback_url(course.id, assessment.id))
      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "403 for students", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get!(Course, course_id)
      assessment = insert(:assessment, course: course)

      conn = get(conn, feedback_url(course_id, assessment.id))
      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "returns all feedback when question_id is absent", %{conn: conn} do
      %{assessment: assessment} = seed_feedback(conn)

      resp =
        conn
        |> get(feedback_url(conn.assigns.course_id, assessment.id))
        |> json_response(200)

      assert length(resp) == 2
      assert Enum.all?(resp, &Map.has_key?(&1, "id"))
      assert Enum.all?(resp, &Map.has_key?(&1, "rating"))
      assert Enum.all?(resp, &Map.has_key?(&1, "body"))
      assert Enum.all?(resp, &Map.has_key?(&1, "user_name"))
      assert Enum.all?(resp, &Map.has_key?(&1, "question_id"))
      assert Enum.all?(resp, &Map.has_key?(&1, "inserted_at"))
    end

    @tag authenticate: :staff
    test "filters feedback by question_id query param", %{conn: conn} do
      %{assessment: assessment, question_1: question_1} = seed_feedback(conn)

      resp =
        conn
        |> get(feedback_url(conn.assigns.course_id, assessment.id), %{
          "question_id" => question_1.id
        })
        |> json_response(200)

      assert length(resp) == 1

      [entry] = resp
      assert entry["question_id"] == question_1.id
      assert entry["user_name"] == "Alice"
      assert entry["rating"] == 5
      assert entry["body"] == "Very helpful"
    end
  end

  describe "POST /v2/courses/:course_id/admin/llm-stats/:assessment_id/feedback" do
    test "401 when not logged in", %{conn: conn} do
      course = insert(:course)
      assessment = insert(:assessment, course: course)

      conn =
        post(conn, feedback_url(course.id, assessment.id), %{"rating" => 5, "body" => "Great"})

      assert response(conn, 401) =~ "Unauthorised"
    end

    @tag authenticate: :student
    test "403 for students", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get!(Course, course_id)
      assessment = insert(:assessment, course: course)

      conn =
        post(conn, feedback_url(course_id, assessment.id), %{"rating" => 5, "body" => "Great"})

      assert response(conn, 403) =~ "Forbidden"
    end

    @tag authenticate: :staff
    test "creates feedback successfully", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get!(Course, course_id)
      assessment = insert(:assessment, course: course)
      question = insert(:question, assessment: assessment, display_order: 1)

      resp =
        conn
        |> post(feedback_url(course_id, assessment.id), %{
          "question_id" => question.id,
          "rating" => 4,
          "body" => "Reasonably useful"
        })
        |> json_response(201)

      assert resp == %{"message" => "Feedback submitted successfully"}

      [saved_feedback] = LLMStats.get_feedback(course_id, assessment.id, question.id)
      assert saved_feedback.rating == 4
      assert saved_feedback.body == "Reasonably useful"
      assert saved_feedback.user_name == conn.assigns.current_user.name
    end

    @tag authenticate: :staff
    test "returns 400 when payload is invalid", %{conn: conn} do
      course_id = conn.assigns.course_id
      course = Repo.get!(Course, course_id)
      assessment = insert(:assessment, course: course)

      resp =
        conn
        |> post(feedback_url(course_id, assessment.id), %{"rating" => 6})
        |> json_response(400)

      assert resp == %{"error" => "Failed to submit feedback"}
    end
  end

  defp seed_usage_logs(conn) do
    course = Repo.get!(Course, conn.assigns.course_id)
    assessment = insert(:assessment, course: course)
    question_1 = insert(:question, assessment: assessment, display_order: 1)
    question_2 = insert(:question, assessment: assessment, display_order: 2)

    student_1 = insert(:course_registration, course: course, role: :student)
    student_2 = insert(:course_registration, course: course, role: :student)

    submission_1 = insert(:submission, assessment: assessment, student: student_1)
    submission_2 = insert(:submission, assessment: assessment, student: student_2)

    answer_11 = insert(:answer, submission: submission_1, question: question_1)
    answer_12 = insert(:answer, submission: submission_1, question: question_2)
    answer_21 = insert(:answer, submission: submission_2, question: question_1)

    assert {:ok, _} =
             LLMStats.log_usage(%{
               course_id: course.id,
               assessment_id: assessment.id,
               question_id: question_1.id,
               answer_id: answer_11.id,
               submission_id: submission_1.id,
               user_id: student_1.user_id
             })

    assert {:ok, _} =
             LLMStats.log_usage(%{
               course_id: course.id,
               assessment_id: assessment.id,
               question_id: question_1.id,
               answer_id: answer_11.id,
               submission_id: submission_1.id,
               user_id: student_1.user_id
             })

    assert {:ok, _} =
             LLMStats.log_usage(%{
               course_id: course.id,
               assessment_id: assessment.id,
               question_id: question_1.id,
               answer_id: answer_21.id,
               submission_id: submission_2.id,
               user_id: student_2.user_id
             })

    assert {:ok, _} =
             LLMStats.log_usage(%{
               course_id: course.id,
               assessment_id: assessment.id,
               question_id: question_2.id,
               answer_id: answer_12.id,
               submission_id: submission_1.id,
               user_id: student_1.user_id
             })

    %{
      assessment: assessment,
      question_1: question_1,
      question_2: question_2
    }
  end

  defp seed_feedback(conn) do
    course = Repo.get!(Course, conn.assigns.course_id)
    assessment = insert(:assessment, course: course)
    question_1 = insert(:question, assessment: assessment, display_order: 1)
    question_2 = insert(:question, assessment: assessment, display_order: 2)
    user_1 = insert(:user, name: "Alice")
    user_2 = insert(:user, name: "Bob")

    assert {:ok, _} =
             LLMStats.submit_feedback(%{
               course_id: course.id,
               assessment_id: assessment.id,
               question_id: question_1.id,
               user_id: user_1.id,
               rating: 5,
               body: "Very helpful"
             })

    assert {:ok, _} =
             LLMStats.submit_feedback(%{
               course_id: course.id,
               assessment_id: assessment.id,
               question_id: question_2.id,
               user_id: user_2.id,
               rating: 3,
               body: "Could be clearer"
             })

    %{
      assessment: assessment,
      question_1: question_1,
      question_2: question_2
    }
  end

  defp assessment_stats_url(course_id, assessment_id) do
    "/v2/courses/#{course_id}/admin/llm-stats/#{assessment_id}"
  end

  defp question_stats_url(course_id, assessment_id, question_id) do
    "/v2/courses/#{course_id}/admin/llm-stats/#{assessment_id}/#{question_id}"
  end

  defp feedback_url(course_id, assessment_id) do
    "/v2/courses/#{course_id}/admin/llm-stats/#{assessment_id}/feedback"
  end
end
