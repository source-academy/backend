defmodule CadetWeb.AICodeAnalysisController do
  use CadetWeb, :controller
  use PhoenixSwagger
  require HTTPoison
  require Logger

  alias Cadet.Assessments

  @openai_api_url "https://api.openai.com/v1/chat/completions"
  @model "gpt-4o"
  @api_key Application.get_env(:openai, :api_key)


  # For logging outputs to a file
  defp log_to_csv(submission_id, question_id, input, student_submission, output, error \\ nil) do
    log_file = "log/ai_comments.csv"
    File.mkdir_p!("log")

    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.to_string()
    input_str = Jason.encode!(input) |> String.replace("\"", "\"\"")
    student_submission_str = Jason.encode!(student_submission) |> String.replace("\"", "\"\"")
    output_str = Jason.encode!(output) |> String.replace("\"", "\"\"")
    error_str = if is_nil(error), do: "", else: Jason.encode!(error) |> String.replace("\"", "\"\"")

    csv_row = "\"#{timestamp}\",\"#{submission_id}\",\"#{question_id}\",\"#{input_str}\",\"#{student_submission_str}\",\"#{output_str}\",\"#{error_str}\"\n"

    File.write!(log_file, csv_row, [:append])
  end


  @doc """
  Fetches the question details and answers based on submissionid and questionid and generates AI-generated comments.
  """
  def generate_ai_comments(conn, %{"submissionid" => submission_id, "questionid" => question_id})
    when is_ecto_id(submission_id) do
      case Assessments.get_answers_in_submission(submission_id, question_id) do
        {:ok, {answers, _assessment}} ->
          analyze_code(conn, answers, submission_id, question_id)

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

  def format_answers(json_string) do
    {:ok, answers} = Jason.decode(json_string)

    answers
    |> Enum.map(&format_answer/1)
    |> Enum.join("\n\n")
  end

  defp format_answer(answer) do
    """
    **Question ID: #{answer["question"]["id"]}**

    **Question:**
    #{answer["question"]["content"]}

    **Solution:**
    ```
    #{answer["question"]["solution"]}
    ```

    **Answer:**
    ```
    #{answer["answer"]["code"]}
    ```

    **Autograding Status:** #{answer["autograding_status"]}
    **Autograding Results:** #{format_autograding_results(answer["autograding_results"])}
    **Comments:** #{answer["comments"] || "None"}
    """
  end

  defp format_autograding_results([]), do: "None"
  defp format_autograding_results(results), do: Enum.join(results, ", ")

  defp analyze_code(conn, answers, submission_id, question_id) do
    answers_json =
      answers
      |> Enum.map(fn answer ->
        question_data =
          if answer.question do
            %{
              id: answer.question_id,
              content: Map.get(answer.question.question, "content"),
              solution: Map.get(answer.question.question, "solution")
            }
          else
            %{
              id: nil,
              content: nil
            }
          end
        answer
        |> Map.from_struct()
        |> Map.take([
          :id,
          :comments,
          :autograding_status,
          :autograding_results,
          :answer,
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

      For example: "This is a good answer.|||This is a bad answer.|||This is a great answer."
      """

      prompt = raw_prompt <> "\n" <> answers_json


    input = %{
      model: @model,
      messages: [
        %{role: "system", content: "You are an expert software engineer and educator."},
        %{role: "user", content: prompt}
      ],
      temperature: 0.5
    } |> Jason.encode!()

    headers = [
      {"Authorization", "Bearer #{@api_key}"},
      {"Content-Type", "application/json"}
    ]


    case HTTPoison.post(@openai_api_url, input, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => response}}]}} ->
            log_to_csv(submission_id, question_id, raw_prompt, answers_json, response)
            comments_list = String.split(response, "|||")

            filtered_comments = Enum.filter(comments_list, fn comment ->
              String.trim(comment) != ""
            end)

            json(conn, %{"comments" => filtered_comments})

          {:error, _} ->
            log_to_csv(submission_id, question_id, raw_prompt, answers_json, nil, "Failed to parse response from OpenAI API")
            json(conn, %{"error" => "Failed to parse response from OpenAI API"})
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        log_to_csv(submission_id, question_id, raw_prompt, answers_json, nil, "API request failed with status #{status}")
        json(conn, %{"error" => "API request failed with status #{status}: #{body}"})

      {:error, %HTTPoison.Error{reason: reason}} ->
        log_to_csv(submission_id, question_id, raw_prompt, answers_json, nil, reason)
        json(conn, %{"error" => "HTTP request error: #{inspect(reason)}"})
    end
  end

  swagger_path :generate_ai_comments do
    post("/courses/{courseId}/admin/generate-comments/{submissionId}/{questionId}")

    summary("Generate AI comments for a given submission.")

    security([%{JWT: []}])

    consumes("application/json")
    produces("application/json")

    parameters do
      submissionId(:path, :integer, "submission id", required: true)
      questionId(:path, :integer, "question id", required: true)
    end

    response(200, "OK", Schema.ref(:GenerateAIComments))
    response(400, "Invalid or missing parameter(s) or submission and/or question not found")
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
        end
    }
  end
end
