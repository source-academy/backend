defmodule Cadet.Autograder.PlagiarismChecker do
  @moduledoc """
  This module performs the plagiarism check script and sends results to
  Amazon S3.
  """
  use Cadet, :context
  use Que.Worker

  require Logger

  import Ecto.Query

  # TODO: change to env var
  @bucket_name "stg-cadet-plagiarism-reports"
  # TODO: change to env var
  @plagiarism_script_path "../grader/TA_CS1101S/mosspy_submission.py"

  def perform(assessment_id) when is_ecto_id(assessment_id) do
    Logger.info("Running plagiarism check on Assessment #{assessment_id}")

    script_result =
      System.cmd("python", [@plagiarism_script_path, "--assessment_id", to_string(assessment_id)])

    script_result
    |> elem(1)
    |> zip_results()
    |> store()
  end

  def store(assessment_id) when is_ecto_id(assessment_id) do
    file_name = "assessment_#{assessment_id}.zip"

    assessment_title =
      Cadet.Assessments.Assessment
      |> where(id: ^assessment_id)
      |> select([a], a.title)
      |> Repo.one()

    response =
      @bucket_name
      |> ExAws.S3.put_object("/reports/assessment-#{assessment_title}", File.read!(file_name))
      |> ExAws.request!()

    # if response status < 400, the transaction was successful.
    if Map.get(response, :status_code) < 400 do
      File.rm(file_name)
      File.rm_rf("submissions")
    else
      raise inspect(response)
    end
  end

  defp zip_results(assessment_id) do
    System.cmd("zip", [
      "-r",
      "assessment_#{assessment_id}.zip",
      "submissions/assessment#{assessment_id}/report/",
      "submissions/assessment#{assessment_id}/assessment_report_#{assessment_id}.html"
    ])

    assessment_id
  end
end
