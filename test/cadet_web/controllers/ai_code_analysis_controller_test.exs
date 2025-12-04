import Mock

defmodule CadetWeb.AICodeAnalysisControllerTest do
  use CadetWeb.ConnCase
  alias Cadet.{Repo, AIComments}
  alias Cadet.{AIComments.AIComment, Courses.Course}
  alias CadetWeb.AICommentsHelpers

  setup do
    course_with_llm =
      insert(:course, %{
        enable_llm_grading: true,
        llm_api_key: AICommentsHelpers.encrypt_llm_api_key("test_key"),
        llm_model: "gpt-5-mini",
        llm_api_url: "http://testapi.com",
        llm_course_level_prompt: "Example Prompt"
      })

    example_assessment = insert(:assessment, %{course: course_with_llm})
    new_submission = insert(:submission, %{assessment: example_assessment})
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
     }}
  end

  describe "GET /v2/courses/:course_id/admin/generate-comments/:answer_id" do
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
      # Make the API call
      with_mock OpenAI,
        chat_completion: fn _input, _overrides ->
          {:ok, %{:choices => [%{"message" => %{"content" => "Comment1|||Comment2"}}]}}
        end do
        conn
        |> sign_in(staff_user.user)
        |> post(build_url_generate_ai_comments(course_with_llm.id, answer.id))
        |> json_response(200)
      end

      with_mock OpenAI,
        chat_completion: fn _input, _overrides ->
          {:ok, %{:choices => [%{"message" => %{"content" => "Comment1|||Comment2"}}]}}
        end do
        response =
          conn
          |> sign_in(admin_user.user)
          |> post(build_url_generate_ai_comments(course_with_llm.id, answer.id))
          |> json_response(200)

        # Verify response
        assert response["comments"] == ["Comment1", "Comment2"]
      end

      # Verify database entry
      comments = Repo.all(AIComment)
      assert length(comments) > 0
      latest_comment = List.first(comments)
      assert latest_comment.answer_id == answer.id
      assert latest_comment.raw_prompt != nil
      assert latest_comment.answers_json != nil
    end

    test "errors out when given an invalid answer id", %{
      conn: conn,
      admin_user: admin_user,
      staff_user: staff_user,
      course_with_llm: course_with_llm,
      example_assessment: example_assessment,
      new_submission: new_submission,
      question: question,
      answer: answer
    } do
      random_answer_id = 324_324

      # Make the API call that should fail
      with_mock OpenAI, [:passthrough],
        chat_completion: fn _input, _overrides ->
          {:ok, %{:choices => [%{"message" => %{"content" => "Comment1|||Comment2"}}]}}
        end do
        response =
          conn
          |> sign_in(admin_user.user)
          |> post(build_url_generate_ai_comments(course_with_llm.id, random_answer_id))
          |> text_response(400)
      end
    end

    test "LLM endpoint returns an invalid response - should log errors in database", %{
      conn: conn,
      admin_user: admin_user,
      staff_user: staff_user,
      course_with_llm: course_with_llm,
      example_assessment: example_assessment,
      new_submission: new_submission,
      question: question,
      answer: answer
    } do
      # Make the API call that should fail
      with_mock OpenAI, [:passthrough],
        chat_completion: fn _input, _overrides ->
          {:ok, %{"body" => "Some unexpected response"}}
        end do
        response =
          conn
          |> sign_in(admin_user.user)
          |> post(build_url_generate_ai_comments(course_with_llm.id, answer.id))
          |> text_response(502)
      end

      # Verify database entry even with error
      comments = Repo.all(AIComment)
      assert length(comments) > 0
      latest_comment = List.first(comments)
      assert latest_comment.answer_id == answer.id
      assert latest_comment.raw_prompt != nil
      assert latest_comment.answers_json != nil
    end
  end

  defp build_url_generate_ai_comments(course_id, answer_id) do
    "/v2/courses/#{course_id}/admin/generate-comments/#{answer_id}"
  end
end
