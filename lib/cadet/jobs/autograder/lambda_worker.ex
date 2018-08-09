defmodule Cadet.Autograder.LambdaWorker do
  @moduledoc """
  This module submits the answer to the autograder and creates a job for the ResultStoreWorker to
  write it to db on success.
  """
  use Que.Worker, concurrency: 20

  require Logger

  alias Cadet.Autograder.ResultStoreWorker

  @lambda_name :cadet |> Application.fetch_env!(:autograder) |> Keyword.get(:lambda_name)

  def build_request_params(%{question: question, answer: answer}) do
    question_content = question.question

    {_, capitalised_name_external} =
      question.grading_library.external
      |> Map.from_struct()
      |> Map.get_and_update(
        :name,
        &{&1, &1 |> Atom.to_string() |> String.upcase()}
      )

    %{
      graderPrograms: question_content["autograder"],
      studentProgram: answer.answer["code"],
      library: %{
        chapter: question.grading_library.chapter,
        external: capitalised_name_external,
        globals: Enum.map(question.grading_library.globals, fn {k, v} -> [k, v] end)
      }
    }
  end

  def perform(params = %{answer: answer}) do
    lambda_params = build_request_params(params)

    response =
      @lambda_name
      |> ExAws.Lambda.invoke(lambda_params, %{})
      |> ExAws.request!()

    # If the lambda crashes, results are in the format of:
    # %{"errorMessage" => "${message}"}
    inspect(response)

    if is_map(response) do
      raise inspect(response)
    else
      result =
        response
        |> parse_response(lambda_params)
        |> Map.put(:status, :success)

      Que.add(ResultStoreWorker, %{answer_id: answer.id, result: result})
    end
  end

  def on_failure(%{answer: answer}, error) do
    Logger.error(
      "Failed to get autograder result. answer_id: #{answer.id}, error: #{inspect(error)}"
    )

    Que.add(
      ResultStoreWorker,
      %{
        answer_id: answer.id,
        result: %{
          grade: 0,
          status: :failed,
          errors: [
            %{"systemError" => "Autograder runtime error. Please contact a system administrator"}
          ]
        }
      }
    )
  end

  def parse_response(response, %{graderPrograms: grader_programs}) do
    response
    |> Enum.zip(grader_programs)
    |> Enum.reduce(
      %{grade: 0, errors: []},
      fn {result, grader_program}, %{grade: grade, errors: errors} ->
        if result["resultType"] == "pass" do
          %{grade: grade + result["grade"], errors: errors}
        else
          error_result = %{
            grader_program: grader_program,
            errors: result["errors"]
          }

          %{grade: grade, errors: errors ++ [error_result]}
        end
      end
    )
  end
end
