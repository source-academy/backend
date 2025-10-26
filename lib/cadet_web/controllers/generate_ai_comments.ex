defmodule CadetWeb.AICodeAnalysisController do
  use CadetWeb, :controller
  use PhoenixSwagger
  require HTTPoison
  require Logger

  alias Cadet.{Assessments, AIComments, Courses}

  # For logging outputs to both database and file
  defp save_comment(submission_id, question_id, raw_prompt, answers_json, response, error \\ nil) do
    # Log to database
    attrs = %{
      submission_id: submission_id,
      question_id: question_id,
      raw_prompt: raw_prompt,
      answers_json: answers_json,
      response: response,
      error: error
    }

    # Check if a comment already exists for the given submission_id and question_id
    case AIComments.get_latest_ai_comment(submission_id, question_id) do
      nil ->
        # If no existing comment, create a new one
        case AIComments.create_ai_comment(attrs) do
          {:ok, comment} ->
            {:ok, comment}

          {:error, changeset} ->
            Logger.error("Failed to log AI comment to database: #{inspect(changeset.errors)}")
            {:error, changeset}
        end

      existing_comment ->
        # Convert the existing comment struct to a map before merging
        updated_attrs = Map.merge(Map.from_struct(existing_comment), attrs)

        case AIComments.update_ai_comment(existing_comment.id, updated_attrs) do
          {:error, :not_found} ->
            Logger.error("AI comment to update not found in database")
            {:error, :not_found}

          {:ok, updated_comment} ->
            {:ok, updated_comment}

          {:error, changeset} ->
            Logger.error("Failed to update AI comment in database: #{inspect(changeset.errors)}")
            {:error, changeset}
        end
    end
  end

  defp check_llm_grading_parameters(llm_api_key, llm_model, llm_api_url, llm_course_level_prompt) do
    cond do
      is_nil(llm_model) or llm_model == "" ->
        {:parameter_error, "LLM model is not configured for this course"}

      is_nil(llm_api_url) or llm_api_url == "" ->
        {:parameter_error, "LLM API URL is not configured for this course"}

      is_nil(llm_course_level_prompt) or llm_course_level_prompt == "" ->
        {:parameter_error, "LLM course-level prompt is not configured for this course"}

      true ->
        {:ok}
    end
  end

  defp ensure_llm_enabled(course) do
    if course.enable_llm_grading do
      {:ok}
    else
      {:error, {:forbidden, "LLM grading is not enabled for this course"}}
    end
  end

  @doc """
  Fetches the question details and answers based on submissionid and questionid and generates AI-generated comments.
  """
  def generate_ai_comments(conn, %{
        "submissionid" => submission_id,
        "questionid" => question_id,
        "course_id" => course_id
      })
      when is_ecto_id(submission_id) do
    with {qid, ""} <- Integer.parse(question_id),
         {:ok, course} <- Courses.get_course_config(course_id),
         {:ok} <- ensure_llm_enabled(course),
         {:ok, key} <- decrypt_llm_api_key(course.llm_api_key),
         {:ok} <-
           check_llm_grading_parameters(
             key,
             course.llm_model,
             course.llm_api_url,
             course.llm_course_level_prompt
           ),
         {:ok, {answers, _}} <- Assessments.get_answers_in_submission(submission_id, qid) do
      # Get head of answers (should only be one answer for given submission
      # and question since we filter to only 1 question)
      case answers do
        [] ->
          conn
          |> put_status(:not_found)
          |> text("No answer found for the given submission and question_id")

        _ ->
          analyze_code(
            conn,
            %{
              answer: hd(answers),
              submission_id: submission_id,
              question_id: qid,
              api_key: key,
              llm_model: course.llm_model,
              llm_api_url: course.llm_api_url,
              course_prompt: course.llm_course_level_prompt,
              assessment_prompt: Assessments.get_llm_assessment_prompt(qid)
            }
          )
      end
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid question ID format")

      {:decrypt_error, err} ->
        conn
        |> put_status(:internal_server_error)
        |> text("Failed to decrypt LLM API key: #{inspect(err)}")

      # Errors for check_llm_grading_parameters
      {:parameter_error, error_msg} ->
        conn
        |> put_status(:bad_request)
        |> text(error_msg)

      {:error, {status, message}} ->
        conn
        |> put_status(status)
        |> text(message)
    end
  end

  defp transform_answers(answers) do
    Enum.map(answers, fn answer ->
      %{
        id: answer.id,
        comments: answer.comments,
        autograding_status: answer.autograding_status,
        autograding_results: answer.autograding_results,
        code: answer.answer["code"],
        question_id: answer.question_id,
        question_content: answer.question["content"]
      }
    end)
  end

  defp format_student_answer(answer) do
    """
    **Student Answer:**
    ```
    #{answer.answer["code"] || "N/A"}
    ```
    """
  end

  defp format_system_prompt(course_prompt, assessment_prompt, answer) do
    (course_prompt || "") <>
      "\n\n" <>
      (assessment_prompt || "") <>
      "\n\n" <>
      """
      **Additional Instructions for this Question:**
      #{answer.question.question["llm_prompt"] || "N/A"}

      **Question:**
      ```
      #{answer.question.question["content"] || "N/A"}
      ```

      **Model Solution:**
      ```
      #{answer.question.question["solution"] || "N/A"}
      ```

      **Autograding Status:** #{answer.autograding_status || "N/A"}
      **Autograding Results:** #{format_autograding_results(answer.autograding_results)}

      The student answer will be given below as part of the User Prompt.
      """
  end

  defp format_autograding_results(nil), do: "N/A"

  defp format_autograding_results(results) when is_list(results) do
    Enum.map_join(results, "; ", fn result ->
      "Error: #{result["errorMessage"] || "N/A"}, Type: #{result["errorType"] || "N/A"}"
    end)
  end

  defp format_autograding_results(results), do: inspect(results)

  def call_llm_endpoint(llm_api_url, input, headers) do
    HTTPoison.post(llm_api_url, input, headers,
      timeout: 60_000,
      recv_timeout: 60_000
    )
  end

  defp analyze_code(
         conn,
         %{
           answer: answer,
           submission_id: submission_id,
           question_id: question_id,
           api_key: api_key,
           llm_model: llm_model,
           llm_api_url: llm_api_url,
           course_prompt: course_prompt,
           assessment_prompt: assessment_prompt
         }
       ) do
    formatted_answer =
      answer
      |> format_student_answer()
      |> Jason.encode!()

    system_prompt = format_system_prompt(course_prompt, assessment_prompt, answer)
    # Combine prompts if llm_prompt exists
    input =
      %{
        model: llm_model,
        messages: [
          %{role: "system", content: system_prompt},
          %{role: "user", content: formatted_answer}
        ]
      }
      |> Jason.encode!()

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case call_llm_endpoint(llm_api_url, input, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => response}}]}} ->
            save_comment(submission_id, question_id, system_prompt, formatted_answer, response)
            comments_list = String.split(response, "|||")

            filtered_comments =
              Enum.filter(comments_list, fn comment ->
                String.trim(comment) != ""
              end)

            json(conn, %{"comments" => filtered_comments})

          {:ok, other} ->
            save_comment(
              submission_id,
              question_id,
              system_prompt,
              formatted_answer,
              Jason.encode!(other),
              "Unexpected JSON shape"
            )

            conn
            |> put_status(:bad_gateway)
            |> text("Unexpected response format from OpenAI API")

          {:error, err} ->
            save_comment(
              submission_id,
              question_id,
              system_prompt,
              formatted_answer,
              nil,
              "Failed to parse response from OpenAI API"
            )

            conn
            |> put_status(:internal_server_error)
            |> text("Failed to parse response from OpenAI API")
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        save_comment(
          submission_id,
          question_id,
          system_prompt,
          formatted_answer,
          nil,
          "API request failed with status #{status}"
        )

        conn
        |> put_status(:internal_server_error)
        |> text("API request failed with status #{status}: #{body}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        save_comment(submission_id, question_id, system_prompt, formatted_answer, nil, reason)

        conn
        |> put_status(:internal_server_error)
        |> text("HTTP request error: #{inspect(reason)}")
    end
  end

  @doc """
  Saves the final comment chosen for a submission.
  """
  def save_final_comment(conn, %{
        "submissionid" => submission_id,
        "questionid" => question_id,
        "comment" => comment
      }) do
    case AIComments.update_final_comment(submission_id, question_id, comment) do
      {:ok, _updated_comment} ->
        json(conn, %{"status" => "success"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> text("Failed to save final comment")
    end
  end

  swagger_path :generate_ai_comments do
    post("/courses/{courseId}/admin/generate-comments/{submissionId}/{questionId}")

    summary("Generate AI comments for a given submission.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      courseId(:path, :integer, "course id", required: true)
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
    end

    response(200, "OK", Schema.ref(:GenerateAIComments))
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorized")
    response(403, "Forbidden")
    response(403, "LLM grading is not enabled for this course")
  end

  swagger_path :save_final_comment do
    post("/courses/{courseId}/admin/save-final-comment/{submissionId}/{questionId}")

    summary("Save the final comment chosen for a submission.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
      comment(:body, :string, "The final comment to save", required: true)
    end

    response(200, "OK", Schema.ref(:SaveFinalComment))
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorized")
    response(403, "Forbidden")
  end

  def swagger_definitions do
    %{
      GenerateAIComments:
        swagger_schema do
          properties do
            comments(:string, "AI-generated comments on the submission answers")
          end
        end,
      SaveFinalComment:
        swagger_schema do
          properties do
            status(:string, "Status of the operation")
          end
        end
    }
  end

  defp decrypt_llm_api_key(nil), do: nil

  defp decrypt_llm_api_key(encrypted_key) do
    case Application.get_env(:openai, :encryption_key) do
      secret when is_binary(secret) and byte_size(secret) >= 16 ->
        key = binary_part(secret, 0, min(32, byte_size(secret)))

        case Base.decode64(encrypted_key) do
          {:ok, decoded} ->
            iv = binary_part(decoded, 0, 16)
            tag = binary_part(decoded, 16, 16)
            ciphertext = binary_part(decoded, 32, byte_size(decoded) - 32)

            case :crypto.crypto_one_time_aead(:aes_gcm, key, iv, ciphertext, "", tag, false) do
              plain_text when is_binary(plain_text) -> {:ok, plain_text}
              _ -> {:decrypt_error, :decryption_failed}
            end

          _ ->
            Logger.error(
              "Failed to decode encrypted key, is it a valid AES-256 key of 16, 24 or 32 bytes?"
            )

            {:decrypt_error, :decryption_failed}
        end

      _ ->
        Logger.error("Encryption key not configured")
        {:decrypt_error, :invalid_encryption_key}
    end
  end
end
