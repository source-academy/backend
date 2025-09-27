defmodule CadetWeb.AICodeAnalysisController do
  use CadetWeb, :controller
  use PhoenixSwagger
  require HTTPoison
  require Logger

  alias Cadet.{Assessments, AIComments, Courses}

  @openai_api_url "https://api.openai.com/v1/chat/completions"
  @model "gpt-4o"
  # To set whether LLM grading is enabled across Source Academy
  @default_llm_grading false

  # For logging outputs to both database and file
  defp save_comment(submission_id, question_id, raw_prompt, answers_json, response, error \\ nil) do
    # Log to database
    attrs = %{
      submission_id: submission_id,
      question_id: question_id,
      raw_prompt: raw_prompt,
      answers_json: answers_json,
      response: response,
      error: error,
      inserted_at: NaiveDateTime.utc_now()
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

  @doc """
  Fetches the question details and answers based on submissionid and questionid and generates AI-generated comments.
  """
  def generate_ai_comments(conn, %{
        "submissionid" => submission_id,
        "questionid" => question_id,
        "course_id" => course_id
      })
      when is_ecto_id(submission_id) do
    # Check if LLM grading is enabled for this course (default to @default_llm_grading if nil)
    case Courses.get_course_config(course_id) do
      {:ok, course} ->
        if course.enable_llm_grading || @default_llm_grading do
          # Get API key from course config or fall back to environment variable
          decrypted_api_key = decrypt_llm_api_key(course.llm_api_key)
          api_key = decrypted_api_key || Application.get_env(:openai, :api_key)

          if is_nil(api_key) do
            conn
            |> put_status(:internal_server_error)
            |> json(%{"error" => "No OpenAI API key configured"})
          else
            case Assessments.get_answers_in_submission(submission_id, question_id) do
              {:ok, {answers, _assessment}} ->
                analyze_code(conn, answers, submission_id, question_id, api_key)

              {:error, {status, message}} ->
                conn
                |> put_status(status)
                |> text(message)
            end
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{"error" => "LLM grading is not enabled for this course"})
        end

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

  defp format_answers(json_string) do
    {:ok, answers} = Jason.decode(json_string)

    Enum.map_join(answers, "\n\n", &format_answer/1)
  end

  defp format_answer(answer) do
    """
    **Question ID: #{answer["question"]["id"] || "N/A"}**

    **Question:**
    #{answer["question"]["content"] || "N/A"}

    **Solution:**
    ```
    #{answer["question"]["solution"] || "N/A"}
    ```

    **Answer:**
    ```
    #{answer["answer"]["code"] || "N/A"}
    ```

    **Autograding Status:** #{answer["autograding_status"] || "N/A"}
    **Autograding Results:** #{format_autograding_results(answer["autograding_results"])}
    **Comments:** #{answer["comments"] || "None"}
    """
  end

  defp format_autograding_results(nil), do: "N/A"

  defp format_autograding_results(results) when is_list(results) do
    Enum.map_join(results, "; ", fn result ->
      "Error: #{result["errorMessage"] || "N/A"}, Type: #{result["errorType"] || "N/A"}"
    end)
  end

  defp format_autograding_results(results), do: inspect(results)

  defp analyze_code(conn, answers, submission_id, question_id, api_key) do
    answers_json =
      answers
      |> Enum.map(fn answer ->

        question_data =
          if answer.question do
            %{
              id: answer.question_id,
              content: Map.get(answer.question.question, "content"),
              solution: Map.get(answer.question.question, "solution"),
              llm_prompt: Map.get(answer.question.question, "llm_prompt")
            }
          else
            %{
              id: nil,
              content: nil,
              llm_prompt: nil
            }
          end

        answer
        |> Map.from_struct()
        |> Map.take([
          :id,
          :comments,
          :autograding_status,
          :autograding_results,
          :answer
        ])
        |> Map.put(:question, question_data)
      end)
      |> Jason.encode!()
      |> format_answers()

    raw_prompt = """
    The code below is written in Source, a variant of JavaScript that comes with a rich set of built-in constants and functions. Below is a summary of some key built-in entities available in Source:

    Constants:
    - Infinity: The special number value representing infinity.
    - NaN: The special number value for "not a number."
    - undefined: The special value for an undefined variable.
    - math_PI: The constant π (approximately 3.14159).
    - math_E: Euler's number (approximately 2.71828).

    Functions:
    - __access_export__(exports, lookup_name): Searches for a name in an exports data structure.
    - accumulate(f, initial, xs): Reduces a list by applying a binary function from right-to-left.
    - append(xs, ys): Appends list ys to the end of list xs.
    - char_at(s, i): Returns the character at index i of string s.
    - display(v, s): Displays value v (optionally preceded by string s) in the console.
    - filter(pred, xs): Returns a new list with elements of xs that satisfy the predicate pred.
    - for_each(f, xs): Applies function f to each element of the list xs.
    - get_time(): Returns the current time in milliseconds.
    - is_list(xs): Checks whether xs is a proper list.
    - length(xs): Returns the number of elements in list xs.
    - list(...): Constructs a list from the provided values.
    - map(f, xs): Applies function f to each element of list xs.
    - math_abs(x): Returns the absolute value of x.
    - math_ceil(x): Rounds x up to the nearest integer.
    - math_floor(x): Rounds x down to the nearest integer.
    - pair(x, y): A primitive function that makes a pair whose head (first component) is x and whose tail (second component) is y.
    - head(xs): Returns the first element of pair xs.
    - tail(xs): Returns the second element of pair xs.
    - math_random(): Returns a random number between 0 (inclusive) and 1 (exclusive).

    (For a full list of built-in functions and constants, refer to the Source documentation.)

    Analyze the following submitted answers and provide detailed feedback on correctness, readability, efficiency, and possible improvements. Your evaluation should consider both standard JavaScript features and the additional built-in functions unique to Source.

    Provide between 3 and 5 concise comment suggestions, each under 200 words.

    Your output must include only the comment suggestions, separated exclusively by triple pipes ("|||") with no spaces before or after the pipes, and without any additional formatting, bullet points, or extra text.

    Comments and documentation in the code are not necessary for the code, do not penalise based on that, do not suggest to add comments as well.

    Follow the XP scoring guideline provided below in the question prompt, do not be too harsh!

    For example: "This is a good answer.|||This is a bad answer.|||This is a great answer."
    """

    # Get the llm_prompt from the first answer's question
    llm_prompt =
      answers
      |> List.first()
      |> Map.get(:question)
      |> Map.get(:question)
      |> Map.get("llm_prompt")

    # Combine prompts if llm_prompt exists
    prompt =
      if llm_prompt && llm_prompt != "" do
        raw_prompt <> "Additional Instructions:\n\n" <> llm_prompt <> "\n\n" <> answers_json
      else
        raw_prompt <> "\n" <> answers_json
      end

    input =
      %{
        model: @model,
        messages: [
          %{role: "system", content: "You are an expert software engineer and educator."},
          %{role: "user", content: prompt}
        ],
        temperature: 0.5
      }
      |> Jason.encode!()

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(@openai_api_url, input, headers, timeout: 60_000, recv_timeout: 60_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => response}}]}} ->
            save_comment(submission_id, question_id, prompt, answers_json, response)
            comments_list = String.split(response, "|||")

            filtered_comments =
              Enum.filter(comments_list, fn comment ->
                String.trim(comment) != ""
              end)

            json(conn, %{"comments" => filtered_comments})

          {:error, _} ->
            save_comment(
              submission_id,
              question_id,
              prompt,
              answers_json,
              nil,
              "Failed to parse response from OpenAI API"
            )

            json(conn, %{"error" => "Failed to parse response from OpenAI API"})
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        save_comment(
          submission_id,
          question_id,
          prompt,
          answers_json,
          nil,
          "API request failed with status #{status}"
        )

        conn
        |> put_status(:internal_server_error)
        |> json(%{"error" => "API request failed with status #{status}: #{body}"})

      {:error, %HTTPoison.Error{reason: reason}} ->
        save_comment(submission_id, question_id, prompt, answers_json, nil, reason)
        json(conn, %{"error" => "HTTP request error: #{inspect(reason)}"})
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
        |> json(%{"error" => "Failed to save final comment"})
    end
  end

  @doc """
  Saves the chosen comments for a submission and question.
  Accepts an array of comments in the request body.
  """
  def save_chosen_comments(conn, %{
        "submissionid" => submission_id,
        "questionid" => question_id,
        "comments" => comments
      }) do
    case AIComments.update_chosen_comments(submission_id, question_id, comments) do
      {:ok, _updated_comment} ->
        json(conn, %{"status" => "success"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"error" => "Failed to save chosen comments"})
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
              plain_text when is_binary(plain_text) -> plain_text
              _ -> nil
            end

          _ ->
            Logger.error("Failed to decode encrypted key")
            nil
        end

      _ ->
        Logger.error("Encryption key not configured properly")
        nil
    end
  end
end
