defmodule CadetWeb.AICodeAnalysisControllerTest do
  use CadetWeb.ConnCase
  alias Cadet.AIComments
  alias Cadet.AIComments.AIComment

  setup do
    # Clean up test files before each test
    log_file = "log/ai_comments.csv"
    File.rm(log_file)
    :ok
  end

  describe "generate_ai_comments" do
    test "successfully logs comments to both database and file", %{conn: conn} do
      # Test data
      submission_id = 123
      question_id = 456
      raw_prompt = "Test prompt"
      answers_json = ~s({"test": "data"})
      mock_response = "Comment 1|||Comment 2|||Comment 3"

      # Make the API call
      response =
        conn
        |> post(
          Routes.ai_code_analysis_path(conn, :generate_ai_comments, submission_id, question_id)
        )
        |> json_response(200)

      # Verify database entry
      comments = Repo.all(AIComment)
      assert length(comments) > 0
      latest_comment = List.first(comments)
      assert latest_comment.submission_id == submission_id
      assert latest_comment.question_id == question_id
      assert latest_comment.raw_prompt != nil
      assert latest_comment.answers_json != nil

      # Verify CSV file
      log_file = "log/ai_comments.csv"
      assert File.exists?(log_file)
      file_content = File.read!(log_file)

      # Check if CSV contains the required data
      assert file_content =~ Integer.to_string(submission_id)
      assert file_content =~ Integer.to_string(question_id)
    end

    test "logs error when API call fails", %{conn: conn} do
      # Test data with invalid submission_id to trigger error
      submission_id = -1
      question_id = 456

      # Make the API call that should fail
      response =
        conn
        |> post(
          Routes.ai_code_analysis_path(conn, :generate_ai_comments, submission_id, question_id)
        )
        |> json_response(400)

      # Verify error is logged in database
      comments = Repo.all(AIComment)
      assert length(comments) > 0
      error_log = List.first(comments)
      assert error_log.error != nil
      assert error_log.submission_id == submission_id
      assert error_log.question_id == question_id

      # Verify error is logged in CSV
      log_file = "log/ai_comments.csv"
      assert File.exists?(log_file)
      file_content = File.read!(log_file)
      assert file_content =~ Integer.to_string(submission_id)
      assert file_content =~ Integer.to_string(question_id)
      assert file_content =~ "error"
    end
  end

  describe "save_final_comment" do
    test "successfully saves final comment", %{conn: conn} do
      # First create a comment entry
      submission_id = 123
      question_id = 456
      raw_prompt = "Test prompt"
      answers_json = ~s({"test": "data"})
      response = "Comment 1|||Comment 2|||Comment 3"

      {:ok, _comment} =
        AIComments.create_ai_comment(%{
          submission_id: submission_id,
          question_id: question_id,
          raw_prompt: raw_prompt,
          answers_json: answers_json,
          response: response
        })

      # Now save the final comment
      final_comment = "This is the chosen final comment"

      response =
        conn
        |> post(
          Routes.ai_code_analysis_path(conn, :save_final_comment, submission_id, question_id),
          %{
            comment: final_comment
          }
        )
        |> json_response(200)

      assert response["status"] == "success"

      # Verify the comment was saved
      comment = Repo.get_by(AIComment, submission_id: submission_id, question_id: question_id)
      assert comment.final_comment == final_comment
    end

    test "returns error when no comment exists", %{conn: conn} do
      submission_id = 999
      question_id = 888
      final_comment = "This comment should not be saved"

      response =
        conn
        |> post(
          Routes.ai_code_analysis_path(conn, :save_final_comment, submission_id, question_id),
          %{
            comment: final_comment
          }
        )
        |> json_response(422)

      assert response["error"] == "Failed to save final comment"
    end
  end

  describe "save_chosen_comments" do
    test "successfully saves chosen comments", %{conn: conn} do
      # First create a comment entry
      submission_id = 123
      question_id = 456
      raw_prompt = "Test prompt"
      answers_json = ~s({"test": "data"})
      response = "Comment 1|||Comment 2|||Comment 3"

      {:ok, _comment} =
        AIComments.create_ai_comment(%{
          submission_id: submission_id,
          question_id: question_id,
          raw_prompt: raw_prompt,
          answers_json: answers_json,
          response: response
        })

      # Now save the chosen comments
      chosen_comments = ["Comment 1", "Comment 2"]

      response =
        conn
        |> post(
          Routes.ai_code_analysis_path(conn, :save_chosen_comments, submission_id, question_id),
          %{
            comments: chosen_comments
          }
        )
        |> json_response(200)

      assert response["status"] == "success"

      # Verify the chosen comments were saved
      comment = Repo.get_by(AIComment, submission_id: submission_id, question_id: question_id)
      assert comment.comment_chosen == chosen_comments
    end

    test "returns error when no comment exists", %{conn: conn} do
      submission_id = 999
      question_id = 888
      chosen_comments = ["Comment 1", "Comment 2"]

      response =
        conn
        |> post(
          Routes.ai_code_analysis_path(conn, :save_chosen_comments, submission_id, question_id),
          %{
            comments: chosen_comments
          }
        )
        |> json_response(422)

      assert response["error"] == "Failed to save chosen comments"
    end
  end
end
