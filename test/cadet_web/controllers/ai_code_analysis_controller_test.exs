defmodule CadetWeb.AICodeAnalysisControllerTest do
  use CadetWeb.ConnCase
  alias Cadet.AIComments
  alias Cadet.AIComments.AIComment
  alias Cadet.Courses.Course
  alias Cadet.{Repo}

  setup do
    course_with_llm = insert(:course, %{enable_llm_grading: true, llm_api_key: Course.encrypt_llm_api_key("test_key"), llm_model: "gpt-5-mini", llm_api_url: "http://testapi.com", llm_course_level_prompt: "Example Prompt"})
    example_assessment = insert(:assessment, %{course: course_with_llm})
    new_submission = insert(:submission, %{ assessment: example_assessment})
    question = insert(:programming_question, %{assessment: example_assessment})
    answer = insert(:answer, %{submission: new_submission, question: question})
    admin_user = insert(:course_registration, %{role: :admin, course: course_with_llm})
    staff_user = insert(:course_registration, %{role: :staff, course: course_with_llm})

    {:ok,
      %{
        admin_user: admin_user,
        staff_user: staff_user,
        course_with_llm: course_with_llm,
        example_assessment: example_assessment,
        new_submission: new_submission,
        question: question,
        answer: answer
      }
    }

  end
  describe "GET /v2/courses/:course_id/admin/generate-comments/:submissionid/:questionid" do
    test "success with happy path, admin and staff", %{
      conn: conn,
      admin_user: admin_user,
      staff_user: staff_user,
      course_with_llm: course_with_llm,
      example_assessment: example_assessment,
      new_submission: new_submission,
      question: question,
      answer: answer
    } do
      # Test data
      # Make the API call
      response =
        conn
        |> sign_in(staff_user.user)
        |> post(build_url_generate_ai_comments(course_with_llm.id, new_submission.id, question.id))
        |> json_response(200)

      response =
        conn
        |> sign_in(admin_user.user)
        |> post(build_url_generate_ai_comments(course_with_llm.id, new_submission.id, question.id))
        |> json_response(200)

      # Verify database entry
      comments = Repo.all(AIComment)
      assert length(comments) > 0
      latest_comment = List.first(comments)
      assert latest_comment.submission_id == new_submission.id
      assert latest_comment.question_id == question.id
      assert latest_comment.raw_prompt != nil
      assert latest_comment.answers_json != nil

    end

    # test "logs error when API call fails", %{conn: conn} do
    #   # Test data with invalid submission_id to trigger error
    #   course_1 = courses.course1
    #   submission_id = -1
    #   question_id = 456

    #   admin_user = insert(:course_registration, %{role: :admin, course: course_1})
    #   # Make the API call that should fail
    #   response =
    #     conn
    #     |> sign_in(admin_user.user)
    #     |> post(build_url_generate_ai_comments(course_1.id, submission_id, question_id))
    #     |> json_response(400)

    #   # Verify error is logged in database
    #   comments = Repo.all(AIComment)
    #   assert length(comments) > 0
    #   error_log = List.first(comments)
    #   assert error_log.error != nil
    #   assert error_log.submission_id == submission_id
    #   assert error_log.question_id == question_id
    # end
  end

  defp build_url_generate_ai_comments(course_id, submission_id, question_id) do
    "/v2/courses/#{course_id}/admin/generate-comments/#{submission_id}/#{question_id}"
  end

end
