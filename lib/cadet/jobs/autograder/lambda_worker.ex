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
  rescue
    error -> handle_failure(args, :error, error, __STACKTRACE__)
  catch
    kind, reason -> handle_failure(args, kind, reason, __STACKTRACE__)
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
  def run(args) when is_map(args) do
    question_id = get_arg(args, :question_id)
    answer_id = get_arg(args, :answer_id)
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
      config = Application.fetch_env!(:cadet, :autograder)
      runtime = resolve_runtime(question.grading_library.runtime)

      lambda_name =
        Keyword.get(config, lambda_key_for(runtime)) ||
          raise "No autograder lambda configured for runtime #{inspect(runtime)}"

      response =
        lambda_name
        |> ExAws.Lambda.invoke(lambda_params, %{})
        |> ExAws.request!()

      result = parse_response(response)

      enqueue_result_store(%{
        answer_id: answer.id,
        result: result,
        overwrite: get_arg(args, :overwrite, false)
      })

      :ok
    end
  end

  # might want to check if this is actually needed
  defp resolve_runtime(runtime) when runtime in [nil, ""], do: "python"
  defp resolve_runtime(runtime), do: runtime

  defp lambda_key_for("legacy"), do: :lambda_name
  defp lambda_key_for("python"), do: :python_lambda_name

  defp enqueue_result_store(args) do
    args
    |> ResultStoreWorker.new()
    |> Oban.insert()
  end

  defp handle_failure(args, kind, error, stacktrace) do
    answer_id = get_arg(args, :answer_id)

    error_message =
      "Failed to get autograder result. answer_id: #{answer_id}, " <>
        "error: #{Exception.format(kind, error, stacktrace)}"

    Logger.error(error_message)
    Sentry.capture_message(error_message)

    enqueue_result_store(%{
      answer_id: answer_id,
      result: failed_result(),
      overwrite: get_arg(args, :overwrite, false)
    })

    # Report the failure to Oban so it is recorded as `discarded` (max_attempts:
    # 1) rather than `completed`, keeping Oban telemetry accurate. The failed
    # result has already been enqueued above so the answer is still updated.
    {:error, error_message}
  end

  defp failed_result do
    %{
      score: 0,
      max_score: 1,
      status: :failed,
      result: [
        %{
          "resultType" => "error",
          "errors" => [
            %{
              "errorType" => "systemError",
              "errorMessage" => "Autograder runtime error. Please contact a system administrator"
            }
          ]
        }
      ]
    }
  end

  defp get_arg(args, key, default \\ nil) do
    Map.get(args, key, Map.get(args, Atom.to_string(key), default))
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
        globals: Enum.map(question.grading_library.globals, fn {k, v} -> [k, v] end),
        runtime: question.grading_library.runtime
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
