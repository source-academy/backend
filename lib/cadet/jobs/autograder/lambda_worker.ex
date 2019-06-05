defmodule Cadet.Autograder.LambdaWorker do
  @moduledoc """
  This module submits the answer to the autograder and creates a job for the ResultStoreWorker to
  write the received result to db.
  """
  use Que.Worker, concurrency: 20

  require Logger

  alias Cadet.Autograder.ResultStoreWorker
  alias Cadet.Assessments.{Answer, Question}

  @lambda_name :cadet |> Application.fetch_env!(:autograder) |> Keyword.get(:lambda_name)

  @doc """
  This Que callback transforms an input of %{question: %Question{}, answer: %Answer{}} into
  the correct shape to dispatch to lambda, waits for the response, parses it, and enqueues a
  storage job.
  """
  def perform(params = %{answer: answer = %Answer{}, question: %Question{}}) do
    lambda_params = build_request_params(params)

    response =
      @lambda_name
      |> ExAws.Lambda.invoke(lambda_params, %{})
      |> ExAws.request!()

    result = parse_response(response)

    Que.add(ResultStoreWorker, %{answer_id: answer.id, result: result})
  end

  def on_failure(%{answer: answer = %Answer{}, question: %Question{}}, error) do
    error_message =
      "Failed to get autograder result. answer_id: #{answer.id}, error: #{
        inspect(error, pretty: true)
      }"

    Logger.error(error_message)
    Sentry.capture_message(error_message)

    Que.add(
      ResultStoreWorker,
      %{
        answer_id: answer.id,
        result: %{
          grade: 0,
          status: :failed,
          result: [
            %{
              "resultType" => "error",
              "errors" => [
                %{
                  "errorType" => "systemError",
                  "errorMessage" =>
                    "Autograder runtime error. Please contact a system administrator"
                }
              ]
            }
          ]
        }
      }
    )
  end

  def build_request_params(%{question: question = %Question{}, answer: answer = %Answer{}}) do
    question_content = question.question

    {_, upcased_name_external} =
      question.grading_library.external
      |> Map.from_struct()
      |> Map.get_and_update(
        :name,
        &{&1, &1 |> Atom.to_string() |> String.upcase()}
      )

    %{
      prependProgram: Map.get(question_content, "prepend", ""),
      studentProgram: Map.get(answer.answer, "code"),
      postpendProgram: Map.get(question_content, "postpend", ""),
      testcases:
        Map.get(question_content, "public", []) ++ Map.get(question_content, "private", []),
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
        grade: 0,
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
      %{grade: response["totalScore"], result: response["results"], status: :success}
    end
  end
end
