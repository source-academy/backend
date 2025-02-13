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

      raw_prompt = """
      The code below was written in JavaScript.

      Analyze the following submitted answers and provide feedback on correctness, readability, efficiency, and improvements:

      Provide minimum 3 comment suggestions and maximum 5 comment suggestions. Keep each comment suggestion concise and specific, less than 200 words.

      Only provide your comment suggestions in the output and nothing else.

      Your output should be in the following format.

      DO NOT start the output with |||. Separate each suggestion using |||.

      DO NOT add spaces before or after the |||.

      Only provide the comment suggestions and separate each comment suggestion by using triple pipes ("|||").

      For example: "This is a good answer.|||This is a bad answer.|||This is a great answer."

      Do not provide any other information in the output, like "Here are the comment suggestions for the first answer"

      Do not include any bullet points, number lists, or any other formatting in your output. Just plain text comments, separated by triple pipes ("|||").
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
