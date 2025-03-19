defmodule Cadet.AICommentsTestHelpers do
  @moduledoc """
  Helper functions for testing AI comments functionality.
  """

  alias Cadet.Repo
  alias Cadet.AIComments.AIComment
  import Ecto.Query

  @doc """
  Gets the latest AI comment from the database.
  """
  def get_latest_comment do
    AIComment
    |> first(order_by: [desc: :inserted_at])
    |> Repo.one()
  end

  @doc """
  Gets all AI comments for a specific submission and question.
  """
  def get_comments_for_submission(submission_id, question_id) do
    from(c in AIComment,
      where: c.submission_id == ^submission_id and c.question_id == ^question_id,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Reads the CSV log file and returns its contents.
  """
  def read_csv_log do
    log_file = "log/ai_comments.csv"
    if File.exists?(log_file) do
      File.read!(log_file)
    else
      ""
    end
  end

  @doc """
  Cleans up test artifacts.
  """
  def cleanup_test_artifacts do
    log_file = "log/ai_comments.csv"
    File.rm(log_file)
    Repo.delete_all(AIComment)
  end
end
