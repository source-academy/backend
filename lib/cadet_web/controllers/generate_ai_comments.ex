defmodule CadetWeb.AICodeAnalysisController do
  use CadetWeb, :controller
  use PhoenixSwagger
  require HTTPoison
  require Logger

  alias Cadet.Assessments
  alias Cadet.AIComments

  @openai_api_url "https://api.openai.com/v1/chat/completions"
  @model "gpt-4o"
  @api_key Application.get_env(:openai, :api_key)

  # For logging outputs to both database and file
  defp log_comment(submission_id, question_id, raw_prompt, answers_json, response, error \\ nil) do
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

    case AIComments.create_ai_comment(attrs) do
      {:ok, comment} -> {:ok, comment}
      {:error, changeset} ->
        Logger.error("Failed to log AI comment to database: #{inspect(changeset.errors)}")
        {:error, changeset}
    end

    # Log to file
    try do
      log_file = "log/ai_comments.csv"
      File.mkdir_p!("log")

      timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.to_string()
      raw_prompt_str = Jason.encode!(raw_prompt) |> String.replace("\"", "\"\"")
      answers_json_str = answers_json |> String.replace("\"", "\"\"")
      response_str = if is_nil(response), do: "", else: response |> String.replace("\"", "\"\"")
      error_str = if is_nil(error), do: "", else: error |> String.replace("\"", "\"\"")

      csv_row = "\"#{timestamp}\",\"#{submission_id}\",\"#{question_id}\",\"#{raw_prompt_str}\",\"#{answers_json_str}\",\"#{response_str}\",\"#{error_str}\"\n"

      File.write!(log_file, csv_row, [:append])
    rescue
      e ->
        Logger.error("Failed to log AI comment to file: #{inspect(e)}")
    end
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

      #Agent Role# You are a kind coding assistant and mentor.   #General Instruction on comment style# There is a programming question, and you have to write a comment on the student's answer to the programming question. Note that your reply is addressed directly to the student, so prevent any sentence out of the desired comment in your response to this prompt. The comment includes feedback on the solution's correctness. Suggest improvement areas if necessary. If the answer is incorrect, declare why the answer is wrong, but only give general hints as suggestions and avoid explaining the Right solution. You should keep your tone friendly even if the answer is incorrect and you want to suggest improvements. If there are several problems in the solution, you have to mention all of them. The maximum length of your reply to this prompt can be 50 words. If the answer is correct and you don't have any suggestions, only write "Great job!".   #Prequistic knowledge to solve the question# In this question, you're going to work with Runes. Predefined Runes include heart, circle, square, sail, rcross, nova, corner, and blank. You can access these Runes using their names. You can only use predeclared functions, including "show," "beside," "stack," "beside_frac," "stack_frack," "make_cross," "quarter_turn_left," "quarter_turn_right," "turn_upside_down." These functions are defined below:   1. [Function "show" renders the specified Rune in a tab as a basic drawing. Function prototype: show(rune: Rune): Rune Prototype Description: It takes a Rune parameter as input and returns the specified Rune. Example: "show(heart)" shows a heart shape rune.]   2. [Function "beside" makes a new Rune from two given Runes by placing the first on the left of the second, both occupying equal portions of the width of the result. Function prototype: beside(rune1: Rune, rune2: Rune): Rune  Prototype Description: It takes two parameters of type Rune, rune1 and rune2, as input and returns a Rune. Example 1: "beside(r1, r2)", places r1 on the left of the r2. Example 2: "beside(stack(r1, r2), stack(r3, r4))" places the output of stack(r1, r2) on the left of output of stack(r3, r4). ]   3. [Function "stack" makes a new Rune from two given Runes by placing the first one on top of the second one, each occupying equal parts of the height of the result. Function prototype: stack(rune1: Rune, rune2: Rune): Rune Prototype Description: It takes two parameters of type Rune, rune1 and rune2, as input and returns a Rune. Example1: "stack(r1, r2)" places r1 on top of r2. Example 2: "Stack(beside(r1, r2), beside(r3, r4))" places output of beside(r1, r2) on top of the output of beside(r3, r4).]   4. [Function "beside_frack" Makes a new Rune from two given Runes by placing the first on the left of the second such that the first one occupies a frac portion of the width of the result and the second the rest. Function Prototype: beside_frac(frac: number, rune1: Rune, rune2: Rune): Rune Prototype Description: It takes a number between 0 and 1 as "frac" and two parameters of type Rune, "rune1" and "rune2," as input and returns a Rune parameter. Example 1: "beside_frac(1/2, heart, circle) places a heart on the left of the circle, and both occupy 1/2 of the plane." Example 2: "beside_frac(1/4, heart, circle) places a heart on the left of the circle. The heart occupies 1/4 of the plane, and the circle occupies 3/4 of the plane."]   5. [Function "stack_frack" Makes a new Rune from two given Runes by placing the first on top of the second such that the first one occupies a frac portion of the height of the result and the second the rest. Function Prototype:stack_frac(frac: number, rune1: Rune, rune2: Rune): Rune Prototype Description: It takes a number between 0 and 1 as "frac" and two parameters of type Rune, "rune1" and "rune2," as input and returns a Rune parameter. Example 1: "stack_frac(1/2, heart, circle) places a heart on top of the circle, and both occupy 1/2 of the plane." Example 2: "stack_frac(1/4, heart, circle) places a heart on top of the circle. The heart occupies 1/4 of the plane, and the circle occupies 3/4 of the plane."]   6. [Function "make_cross" makes a new Rune from a given Rune by arranging it into a square for copies of the given Rune in different orientations. Function Prototype: make_cross(rune: Rune): Rune Prototype Description: It takes a Rune parameter as input and returns a Rune parameter. Example: "make_cross(heart)" places a heart shape rune on the bottom-left, a 90-degree clockwise rotated heart on the top-left, a 180-degree clockwise rotated heart on the top-right, and a 270-degree clockwise rotated heart on the bottom-right. The final Rune consists of four runes.]   7. [Function "quarter_turn_left" Makes a new Rune from a given Rune by turning it a quarter-turn in an anti-clockwise direction. Function prototype: quarter_turn_right(rune: Rune): Rune  Prototype Description: It takes a Rune parameter as input and returns a Rune parameter. Example 1: "quarter_turn_left(heart)" rotates the heart shape rune 90 degrees in an anti-clockwise direction. Example 2: "quarter_turn_left(stack(r1, r2))" rotates the output of stack(r1, r2) 90 degrees in an anti-clockwise direction. ]   8. [Function "quarter_turn_right" makes a new Rune from a given Rune by turning it a quarter-turn around the center in a clockwise direction. Function prototype: quarter_turn_right(rune: Rune): Rune  Prototype Description: It takes a Rune parameter as input and returns a Rune parameter. Example 1: "quarter_turn_right(heart)" rotates the heart shape rune 90 degrees in a clockwise direction. Example 2: "quarter_turn_right(stack(r1, r2))" rotates the output of stack(r1, r2) 90 degrees in a clockwise direction. ]   9. [Function "turn_upside_down" makes a new Rune from a given Rune by turning it upside-down. Function prototype: turn_upside_down(rune: Rune): Rune Prototype Description: It takes a Rune parameter as input and returns a Rune parameter. Example 1: "turn_upside_down(heart)" rotates a heart shape rune 180 degrees in a clockwise direction. Example 2:  "turn_upside_down(stack(r1, r2))" rotates the output of stack(r1, r2) 180 degrees in a clockwise direction.]     You must only use the Runes and functions declared above and avoid importing any module in your program. You can pass the output of each function as input to another function. For example, consider beside(stack(r2, r1), stack(r3, r4)). First, the inner stack functions get executed. r2 goes to the left of r1, and r3 goes to the left of r4. Then the output Rune of each stack works as input of beside function. meaning output of stak(r2, r1) goes on top of output of stack(r3,r4).    Avoid hard coding.   #Programming question# Write a function hook that takes a fraction "frac" as an input and creates a 'hook' pattern. The fraction input determines the size of the base of the hook.   The output rune:   [Imagine a rectangle divided into two horizontal sections. Each section is the height of a square. Top Section: This section is simply a filled square. Bottom Section: The bottom section is also the size of a square. However, it's divided into two equal parts vertically. The left side of this square is filled (so it looks like a rectangle that's half the width of the square). The right side of this square is blank or empty. So, if you place these two sections on top of one another, you get: A full square on top. Directly below it, on the left side, you have a half-filled square (a rectangle), and on the right side, it's empty. This forms a "hook" rune, with the hook part facing to the left. The overall rune is a square with two times the height of the original squares used to create it. Examples: hook(1): It's simply a square rune. hook(0): A filled square at the top. An empty or blank space at the bottom of the same size as the square. hook(1/2): A full square on top. Below that, on the right side, there's another filled square that's half the width of the full square. On the left side, it's empty. hook(1/5): A full square on top. Below that, on the right side, there's a very thin filled rectangle (only 1/5 the width of the square). The rest (4/5) to the right is empty.]   You will only need to use the square and blank primitive runes and transform them to get the hook. Implement your function in the code below:   "function hook(frac) {  // your answer here }   // Test show(hook(1/5));"   #Sample Solution and feedback#   1. "function hook(frac) {  return stack(square,               quarter_turn_right(                    stack_frac(frac, square, blank))); }   // Test show(hook(1/5));" - Great job!   2. "function hook(frac) {    return frac === 1  ? square  : frac === 0  ? stack(square,blank)  : stack(square,beside_frac(1-frac, blank, square));  }    show(hook(1/5));" - Excellent work!   3."function hook(frac) {  return stack(square,      quarter_turn_left(      stack_frac(1-frac, blank, square))); } show(hook(1/5));"   -Great job!   4."function hook(frac) {  // your answer here    return stack_frac(1/2,square,              beside_frac(1-frac,blank,square)); } // Test show(hook(1/5));" -Good job, However stack_frac(1 / 2, etc) could have been simplified by merely using stack.
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
            log_comment(submission_id, question_id, raw_prompt, answers_json, response)
            comments_list = String.split(response, "|||")

            filtered_comments = Enum.filter(comments_list, fn comment ->
              String.trim(comment) != ""
            end)

            json(conn, %{"comments" => filtered_comments})

          {:error, _} ->
            log_comment(submission_id, question_id, raw_prompt, answers_json, nil, "Failed to parse response from OpenAI API")
            json(conn, %{"error" => "Failed to parse response from OpenAI API"})
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        log_comment(submission_id, question_id, raw_prompt, answers_json, nil, "API request failed with status #{status}")
        json(conn, %{"error" => "API request failed with status #{status}: #{body}"})

      {:error, %HTTPoison.Error{reason: reason}} ->
        log_comment(submission_id, question_id, raw_prompt, answers_json, nil, reason)
        json(conn, %{"error" => "HTTP request error: #{inspect(reason)}"})
    end
  end

  @doc """
  Saves the final comment chosen for a submission.
  """
  def save_final_comment(conn, %{"submissionid" => submission_id, "questionid" => question_id, "comment" => comment}) do
    case AIComments.update_final_comment(submission_id, question_id, comment) do
      {:ok, _updated_comment} ->
        json(conn, %{"status" => "success"})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"error" => "Failed to save final comment"})
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
end
