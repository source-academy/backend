defmodule Cadet.AIComments do
  @moduledoc """
  Handles operations related to AI comments, including creation, updates, and retrieval.
  """

  import Ecto.Query
  alias Cadet.Repo
  alias Cadet.AIComments.AIComment

  @doc """
  Creates a new AI comment log entry.
  """
  def create_ai_comment(attrs \\ %{}) do
    %AIComment{}
    |> AIComment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an AI comment by ID.
  """
  def get_ai_comment(id) do
    case Repo.get(AIComment, id) do
      nil -> {:error, :not_found}
      comment -> {:ok, comment}
    end
  end

  @doc """
  Retrieves an AI comment for a specific submission and question.
  Returns `nil` if no comment exists.
  """
  def get_ai_comments_for_submission(submission_id, question_id) do
    Repo.one(
      from(c in AIComment,
        where: c.submission_id == ^submission_id and c.question_id == ^question_id
      )
    )
  end

  @doc """
  Retrieves the latest AI comment for a specific submission and question.
  Returns `nil` if no comment exists.
  """
  def get_latest_ai_comment(submission_id, question_id) do
    Repo.one(
      from(c in AIComment,
        where: c.submission_id == ^submission_id and c.question_id == ^question_id,
        order_by: [desc: c.inserted_at],
        limit: 1
      )
    )
  end

  @doc """
  Updates the final comment for a specific submission and question.
  Returns the most recent comment entry for that submission/question.
  """
  def update_final_comment(submission_id, question_id, final_comment) do
    comment = get_latest_ai_comment(submission_id, question_id)

    case comment do
      nil ->
        {:error, :not_found}

      _ ->
        comment
        |> AIComment.changeset(%{final_comment: final_comment})
        |> Repo.update()
    end
  end

  @doc """
  Updates an existing AI comment with new attributes.
  """
  def update_ai_comment(id, attrs) do
    id
    |> get_ai_comment()
    |> case do
      {:error, :not_found} -> {:error, :not_found}
      {:ok, comment} ->
        comment
        |> AIComment.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates the chosen comments for a specific submission and question.
  Accepts an array of comments and replaces the existing array in the database.
  """
  def update_chosen_comments(submission_id, question_id, new_comments) do
    comment = get_latest_ai_comment(submission_id, question_id)

    case comment do
      nil ->
        {:error, :not_found}

      _ ->
        comment
        |> AIComment.changeset(%{comment_chosen: new_comments})
        |> Repo.update()
    end
  end
end
