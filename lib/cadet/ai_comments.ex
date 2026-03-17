defmodule Cadet.AIComments do
  @moduledoc """
  Handles operations related to AI comments, including creation, updates, and retrieval.
  """

  import Ecto.Query
  alias Cadet.Repo
  alias Cadet.AIComments.{AIComment, AICommentVersion}

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

  @doc """
  Saves selected comment indices and finalization metadata for an AI comment.
  """
  def save_selected_comments(answer_id, selected_indices, finalized_by_id) do
    case get_latest_ai_comment(answer_id) do
      nil ->
        {:error, :not_found}

      comment ->
        comment
        |> AIComment.changeset(%{
          selected_indices: selected_indices,
          finalized_by_id: finalized_by_id,
          finalized_at: DateTime.truncate(DateTime.utc_now(), :second)
        })
        |> Repo.update()
    end
  end

  @doc """
  Creates a new version entry for a specific comment index.
  Automatically determines the next version number.
  """
  def create_comment_version(ai_comment_id, comment_index, content, editor_id) do
    transaction_result =
      Repo.transaction(fn ->
        # Serialize version creation per (ai_comment_id, comment_index)
        # to avoid duplicate version numbers.
        case Repo.query("SELECT pg_advisory_xact_lock($1, $2)", [ai_comment_id, comment_index]) do
          {:ok, _} ->
            next_version =
              Repo.one(
                from(v in AICommentVersion,
                  where: v.ai_comment_id == ^ai_comment_id and v.comment_index == ^comment_index,
                  select: coalesce(max(v.version_number), 0)
                )
              ) + 1

            case %AICommentVersion{}
                 |> AICommentVersion.changeset(%{
                   ai_comment_id: ai_comment_id,
                   comment_index: comment_index,
                   version_number: next_version,
                   content: content,
                   editor_id: editor_id
                 })
                 |> Repo.insert() do
              {:ok, version} -> version
              {:error, changeset} -> Repo.rollback(changeset)
            end

          {:error, error} ->
            Repo.rollback(error)
        end
      end)

    case transaction_result do
      {:ok, version} -> {:ok, version}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets all versions for a specific AI comment, ordered by comment_index and version_number.
  """
  def get_comment_versions(ai_comment_id) do
    Repo.all(
      from(v in AICommentVersion,
        where: v.ai_comment_id == ^ai_comment_id,
        order_by: [asc: v.comment_index, asc: v.version_number]
      )
    )
  end

  @doc """
  Gets the latest version for a specific comment index.
  """
  def get_latest_version(ai_comment_id, comment_index) do
    Repo.one(
      from(v in AICommentVersion,
        where: v.ai_comment_id == ^ai_comment_id and v.comment_index == ^comment_index,
        order_by: [desc: v.version_number],
        limit: 1
      )
    )
  end
end