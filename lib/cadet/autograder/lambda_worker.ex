defmodule Cadet.Autograder.LambdaWorker do
  @moduledoc """
  This module submits the answer to the autograder and creates a job for the ResultStoreWorker to
  write it to db on success.
  """
  use Que.Worker, concurrency: 20

  require Logger

  alias Cadet.Assessments.Answer

  @api_endpoint :cadet |> Application.fetch_env!(:autograder) |> Keyword.get(:api_endpoint)

  def test_request_params do
    %{
      chapter: 1,
      graderPrograms: [
        "function ek0chei0y1() {\n    return f(0) === 0 ? 1 : 0;\n  }\n\n  ek0chei0y1();",
        "function ek0chei0y1() {\n    const test1 = f(7) === 13;\n    const test2 = f(10) === 55;\n    const test3 = f(12) === 144;\n    return test1 && test2 && test3 ? 4 : 0;\n  }\n\n  ek0chei0y1();"
      ],
      studentProgram: "const f = i => i === 0 ? 0 : i < 3 ? 1 : f(i-1) + f(i-2);"
    }
    |> Jason.encode!()
  end

  def perform(_) do
    case HTTPoison.post!(@api_endpoint, test_request_params()) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        body
        |> parse_body

      %HTTPoison.Response{status_code: status_code} ->
        raise "HTTP Status #{status_code}"
    end
  end

  def on_failure(_, error) do
    Logger.error("Autograder error: #{inspect(error)}")
  end

  def parse_body(body) do
    body
    |> Jason.decode!()
    |> Enum.map(fn result ->
      case result["resultType"] do
        "pass" ->
          result["marks"]

        "error" ->
          0
      end
    end)
    |> Enum.sum()
    |> inspect()
    |> IO.puts()
  end
end
