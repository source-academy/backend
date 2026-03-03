defmodule CadetWeb.AICodeAnalysisController do
  use CadetWeb, :controller
  use PhoenixSwagger
  require HTTPoison
  require Logger

  alias Cadet.{Assessments, AIComments, Courses, LLMStats}
  alias CadetWeb.{AICodeAnalysisController, AICommentsHelpers}

  # For logging outputs to both database and file
  defp save_comment(answer_id, raw_prompt, answers_json, response, error \\ nil) do
    # Log to database
    attrs = %{
      answer_id: answer_id,
      raw_prompt: raw_prompt,
      answers_json: answers_json,
      response: response,
      error: error
    }

    # Check if a comment already exists for the given answer_id
    case AIComments.get_latest_ai_comment(answer_id) do
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
  Fetches the question details and answers based on answer_id and generates AI-generated comments.
  """
  def generate_ai_comments(conn, %{
        "answer_id" => answer_id,
        "course_id" => course_id
      })
      when is_ecto_id(answer_id) do
    with {answer_id_parsed, ""} <- Integer.parse(answer_id),
         {:ok, course} <- Courses.get_course_config(course_id),
         {:ok} <- ensure_llm_enabled(course),
         {:ok, key} <- AICommentsHelpers.decrypt_llm_api_key(course.llm_api_key),
         {:ok} <-
           check_llm_grading_parameters(
             key,
             course.llm_model,
             course.llm_api_url,
             course.llm_course_level_prompt
           ),
         {:ok, answer} <- Assessments.get_answer(answer_id_parsed) do
      # Get head of answers (should only be one answer for given submission
      # and question since we filter to only 1 question)
      analyze_code(
        conn,
        %{
          answer: answer,
          api_key: key,
          llm_model: course.llm_model,
          llm_api_url: course.llm_api_url,
          course_prompt: course.llm_course_level_prompt,
          assessment_prompt: Assessments.get_llm_assessment_prompt(answer.question_id),
          course_id: course_id
        }
      )
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid question ID format")

      {:decrypt_error, err} ->
        conn
        |> put_status(:internal_server_error)
        |> text("Failed to decrypt LLM API key")

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

  defp format_student_answer(answer) do
    """
    **Student Answer:**
    ```
    #{answer.answer["code"] || "N/A"}
    ```
    """
  end

  defp format_system_prompt(course_prompt, assessment_prompt, answer) do
    "**Course Level Prompt:**\n\n" <>
      (course_prompt || "") <>
      "\n\n**Assessment Level Prompt:**" <>
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

  def create_final_messages(
        course_prompt,
        assessment_prompt,
        answer
      ) do
    formatted_answer =
      answer
      |> format_student_answer()
      |> Jason.encode!()

    [
      %{role: "system", content: format_system_prompt(course_prompt, assessment_prompt, answer)},
      %{role: "user", content: formatted_answer}
    ]
  end

  defp format_autograding_results(nil), do: "N/A"

  defp format_autograding_results(results) when is_list(results) do
    Enum.map_join(results, "; ", fn result ->
      "Error: #{result["errorMessage"] || "N/A"}, Type: #{result["errorType"] || "N/A"}"
    end)
  end

  defp format_autograding_results(results), do: inspect(results)

  defp analyze_code(
         conn,
         %{
           answer: answer,
           api_key: api_key,
           llm_model: llm_model,
           llm_api_url: llm_api_url,
           course_prompt: course_prompt,
           assessment_prompt: assessment_prompt,
           course_id: course_id
         }
       ) do
    # Combine prompts if llm_prompt exists
    final_messages =
      create_final_messages(
        course_prompt,
        assessment_prompt,
        answer
      )

    input =
      [
        model: llm_model,
        messages: final_messages
      ]

    case OpenAI.chat_completion(input, %OpenAI.Config{
           api_url: llm_api_url,
           api_key: api_key,
           http_options: [
             # connect timeout
             timeout: 60_000,
             # response timeout
             recv_timeout: 60_000
           ]
         }) do
      {:ok, %{choices: [%{"message" => %{"content" => content}} | _]}} ->
        save_comment(
          answer.id,
          Enum.at(final_messages, 0).content,
          Enum.at(final_messages, 1).content,
          content
        )

        # Log LLM usage for statistics
        LLMStats.log_usage(%{
          course_id: course_id,
          assessment_id: answer.question.assessment_id,
          question_id: answer.question_id,
          answer_id: answer.id,
          submission_id: answer.submission_id,
          user_id: conn.assigns.course_reg.user_id
        })

        comments_list = String.split(content, "|||")

        filtered_comments =
          Enum.filter(comments_list, fn comment ->
            String.trim(comment) != ""
          end)

        json(conn, %{"comments" => filtered_comments})

      {:ok, other} ->
        save_comment(
          answer.id,
          Enum.at(final_messages, 0).content,
          Enum.at(final_messages, 1).content,
          Jason.encode!(other),
          "Unexpected JSON shape"
        )

        conn
        |> put_status(:bad_gateway)
        |> text("Unexpected response format from LLM")

      {:error, reason} ->
        save_comment(
          answer.id,
          Enum.at(final_messages, 0).content,
          Enum.at(final_messages, 1).content,
          nil,
          inspect(reason)
        )

        conn
        |> put_status(:internal_server_error)
        |> text("LLM request error: #{inspect(reason)}")
    end
  end

  @doc """
  Saves the final comment chosen for a submission.
  """
  def save_final_comment(conn, %{
        "answer_id" => answer_id,
        "comment" => comment
      }) do
    case AIComments.update_final_comment(answer_id, comment) do
      {:ok, _updated_comment} ->
        json(conn, %{"status" => "success"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> text("Failed to save final comment")
    end
  end

  @doc """
  Saves the chosen comment indices and optional edits for each selected comment.
  Expects: selected_indices (list of ints), edits (optional map of index => edited_text).
  """
  def save_chosen_comments(
        conn,
        params = %{
          "submissionid" => _submission_id,
          "questionid" => _question_id,
          "answer_id" => answer_id,
          "selected_indices" => selected_indices
        }
      ) do
    editor_id = conn.assigns.course_reg.user_id
    edits = Map.get(params, "edits", %{})

    with ai_comment when not is_nil(ai_comment) <- AIComments.get_latest_ai_comment(answer_id),
         {:ok, _updated} <-
           AIComments.save_selected_comments(answer_id, selected_indices, editor_id) do
      # Split the original response into individual comments
      original_comments =
        (ai_comment.response || "")
        |> String.split("|||")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&(&1 != ""))

      # Create version entries for each edit
      version_results =
        Enum.map(edits, fn {index_str, edited_text} ->
          index = String.to_integer(index_str)
          original = Enum.at(original_comments, index, "")
          diff = compute_diff(original, edited_text)

          AIComments.create_comment_version(
            ai_comment.id,
            index,
            edited_text,
            editor_id,
            diff
          )
        end)

      errors = Enum.filter(version_results, &match?({:error, _}, &1))

      if errors == [] do
        json(conn, %{"status" => "success"})
      else
        conn
        |> put_status(:unprocessable_entity)
        |> text("Failed to save some comment versions")
      end
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> text("AI comment not found for this answer")

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> text("Failed to save chosen comments")
    end
  end

  defp compute_diff(original, edited) do
    original_tokens = tokenize(original)
    edited_tokens = tokenize(edited)

    diff = List.myers_difference(original_tokens, edited_tokens)

    ops =
      diff
      |> Enum.flat_map(fn
        {:eq, tokens} -> [%{op: "eq", text: Enum.join(tokens)}]
        {:del, tokens} -> [%{op: "del", text: Enum.join(tokens)}]
        {:ins, tokens} -> [%{op: "add", text: Enum.join(tokens)}]
      end)

    unified =
      Enum.map_join(ops, fn
        %{op: "eq", text: text} -> " " <> text
        %{op: "del", text: text} -> "-" <> text
        %{op: "add", text: text} -> "+" <> text
      end)

    %{diff_json: %{"ops" => ops}, diff_unified: unified}
  end

  # Splits text into tokens at word boundaries, preserving whitespace and punctuation
  # as separate tokens so the diff is word-level accurate.
  defp tokenize(text) do
    Regex.split(~r/\b/, text, include_captures: false, trim: true)
  end

  swagger_path :generate_ai_comments do
    post("/courses/{course_id}/admin/generate-comments/{answer_id}")

    summary("Generate AI comments for a given submission.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      course_id(:path, :integer, "course id", required: true)
      answer_id(:path, :integer, "answer id", required: true)
    end

    response(200, "OK", Schema.ref(:GenerateAIComments))
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
    response(401, "Unauthorized")
    response(403, "Forbidden")
    response(403, "LLM grading is not enabled for this course")
  end

  swagger_path :save_final_comment do
    post("/courses/{course_id}/admin/save-final-comment/{answer_id}")

    summary("Save the final comment chosen for a submission.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      course_id(:path, :integer, "course id", required: true)
      answer_id(:path, :integer, "answer id", required: true)
      comment(:body, :string, "The final comment to save", required: true)
    end

    response(200, "OK", Schema.ref(:SaveFinalComment))
    response(400, "Invalid or missing parameter(s)")
    response(401, "Unauthorized")
    response(403, "Forbidden")
  end

  swagger_path :save_chosen_comments do
    post("/courses/{course_id}/admin/save-chosen-comments/{submissionid}/{questionid}")

    summary("Save chosen comment indices and optional edits for a submission.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      course_id(:path, :integer, "course id", required: true)
      submissionid(:path, :integer, "submission id", required: true)
      questionid(:path, :integer, "question id", required: true)

      body(:body, Schema.ref(:SaveChosenCommentsBody), "Chosen comments payload", required: true)
    end

    response(200, "OK", Schema.ref(:SaveChosenComments))
    response(404, "AI comment not found")
    response(422, "Failed to save")
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
        end,
      SaveChosenCommentsBody:
        swagger_schema do
          properties do
            answer_id(:integer, "The answer ID", required: true)

            selected_indices(Schema.ref(:IntegerArray), "Indices of chosen comments",
              required: true
            )

            edits(:object, "Map of comment index to edited text")
          end
        end,
      SaveChosenComments:
        swagger_schema do
          properties do
            status(:string, "Status of the operation")
          end
        end
    }
  end
end
