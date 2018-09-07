defmodule Cadet.Autograder.PlagiarismChecker do
  @moduledoc """
  This module performs the plagiarism check script and sends results to
  Amazon S3.
  """
  use Cadet, :context
  use Que.Worker

  require Logger

  import Ecto.Query

  @bucket_name :cadet
               |> Application.fetch_env!(:plagiarism_check_vars)
               |> Keyword.get(:bucket_name)

  @plagiarism_script_path :cadet
                          |> Application.fetch_env!(:plagiarism_check_vars)
                          |> Keyword.get(:plagiarism_script_path)

  def perform(assessment_id) when is_ecto_id(assessment_id) do
    Logger.info("Running plagiarism check on Assessment #{assessment_id}")

    case System.cmd("python", [
           @plagiarism_script_path,
           "--assessment_id",
           to_string(assessment_id)
         ]) do
      {result, 0} ->
        result
        |> Jason.decode!()
        |> Map.get("assessment_id")
        |> zip_results()
        |> store()

      _ ->
        raise "Error running script, please check again"
    end
  end

  defp store(assessment_id) when is_ecto_id(assessment_id) do
    file_name = "submissions/assessment_#{assessment_id}.zip"

    assessment_title =
      Cadet.Assessments.Assessment
      |> where(id: ^assessment_id)
      |> select([a], a.title)
      |> Repo.one()

    response =
      @bucket_name
      |> ExAws.S3.put_object("/reports/assessment-#{assessment_title}.zip", File.read!(file_name))
      |> ExAws.request!()

    if Map.get(response, :status_code) == 200 do
      File.rm(file_name)
      File.rm_rf("submissions")
    else
      raise inspect(response)
    end
  end

  defp zip_results(assessment_id) do
    case System.cmd("zip", [
           "-r",
           "submissions/assessment_#{assessment_id}.zip",
           "submissions/assessment#{assessment_id}/report/",
           "submissions/assessment#{assessment_id}/assessment_report_#{assessment_id}.html"
         ]) do
      {_, 0} -> assessment_id
      {_, _} -> raise "Files cannot be zipped. Please check directories."
    end
  end
end
