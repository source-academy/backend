defmodule Cadet.Autograder.LambdaWorker do
  @moduledoc """
  This module submits the answer to the autograder and creates a job for the ResultStoreWorker to
  write the received result to db.
  """
  use Oban.Worker,
    queue: :autograder,
    max_attempts: 1

  require Logger

  alias Cadet.Assessments.{Answer, Question}
  alias Cadet.Autograder.ResultStoreWorker
  alias Cadet.Repo

  @doc """
  Oban entry point.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    run(args)
  end

  # Backwards-compatible direct entry: tests and other call-sites pass a
  # plain args map.
  def perform(args) when is_map(args) and not is_struct(args) do
    run(args)
  end

  @doc """
  Public entry point used by tests and by code that wants to bypass Oban.
  Accepts a plain args map (not an %Oban.Job{}) with the same shape Oban would
  pass in `args`.
  """
  def run(args = %{question_id: question_id, answer_id: answer_id}) do
    question = Repo.get!(Question, question_id)
    answer = Repo.get!(Answer, answer_id)
    run_with_models(args, answer, question)
  end

  defp run_with_models(args, answer = %Answer{}, question = %Question{}) do
    lambda_params = build_request_params(%{question: question, answer: answer})

    if Enum.empty?(lambda_params.testcases) do
      Logger.warning("No testcases found. Skipping autograding for answer_id: #{answer.id}")
      # Fix for https://github.com/source-academy/backend/issues/472
      Process.sleep(1000)
      :ok
    else
      response =
        :cadet
        |> Application.fetch_env!(:autograder)
        |> Keyword.get(:lambda_name)
        |> ExAws.Lambda.invoke(lambda_params, %{})
        |> ExAws.request!()

      result = parse_response(response)

      enqueue_result_store(%{
        answer_id: answer.id,
        result: result,
        overwrite: Map.get(args, :overwrite, false)
      })

      :ok
    end
  end

  defp enqueue_result_store(args) do
    ResultStoreWorker.new(args)
    |> Oban.insert()
  end

  def on_failure(_args, error) do
    error_message =
      "Failed to get autograder result. error: #{inspect(error, pretty: true)}"

    Logger.error(error_message)
    Sentry.capture_message(error_message)
    :ok
  end

  def build_request_params(%{question: question = %Question{}, answer: answer = %Answer{}}) do
    question_content = question.question

    {_, upcased_name_external} =
      question.grading_library.external
      |> Map.from_struct()
      |> Map.get_and_update(
        :name,
        &{&1, &1 |> String.upcase()}
      )

    %{
      prependProgram: Map.get(question_content, "prepend", ""),
      studentProgram: Map.get(answer.answer, "code"),
      postpendProgram: Map.get(question_content, "postpend", ""),
      testcases:
        Map.get(question_content, "public", []) ++
          Map.get(question_content, "opaque", []) ++ Map.get(question_content, "secret", []),
      library: %{
        chapter: question.grading_library.chapter,
        external: upcased_name_external,
        globals: Enum.map(question.grading_library.globals, fn {k, v} -> [k, v] end)
      }
    }
  end

  defp parse_response(response) when is_map(response) do
    # If the lambda crashes, results are in the format of:
    # %{"errorMessage" => "${message}"}
    if Map.has_key?(response, "errorMessage") do
      %{
        score: 0,
        max_score: 1,
        status: :failed,
        result: [
          %{
            "resultType" => "error",
            "errors" => [
              %{"errorType" => "systemError", "errorMessage" => response["errorMessage"]}
            ]
          }
        ]
      }
    else
      %{
        score: response["totalScore"],
        max_score: response["maxScore"],
        result: response["results"],
        status: :success
      }
    end
  end
end
