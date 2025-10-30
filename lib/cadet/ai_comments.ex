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
  Retrieves the latest AI comment for a specific submission and question.
  Returns `nil` if no comment exists.
  """
  def get_latest_ai_comment(answer_id) do
    Repo.one(
      from(c in AIComment,
        where: c.answer_id == ^answer_id,
        order_by: [desc: c.inserted_at],
        limit: 1
      )
    )
  end

  @doc """
  Updates the final comment for a specific submission and question.
  Returns the most recent comment entry for that submission/question.
  """
  def update_final_comment(answer_id, final_comment) do
    comment = get_latest_ai_comment(answer_id)

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
      {:error, :not_found} ->
        {:error, :not_found}

      {:ok, comment} ->
        comment
        |> AIComment.changeset(attrs)
        |> Repo.update()
    end
  end
end
