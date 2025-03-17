defmodule Cadet.AIComments do
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
  def get_ai_comment!(id), do: Repo.get!(AIComment, id)

  @doc """
  Gets AI comments for a specific submission and question.
  """
  def get_ai_comments_for_submission(submission_id, question_id) do
    from(c in AIComment,
      where: c.submission_id == ^submission_id and c.question_id == ^question_id,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Updates the final comment for a specific submission and question.
  Returns the most recent comment entry for that submission/question.
  """
  def update_final_comment(submission_id, question_id, final_comment) do
    from(c in AIComment,
      where: c.submission_id == ^submission_id and c.question_id == ^question_id,
      order_by: [desc: c.inserted_at],
      limit: 1
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      comment ->
        comment
        |> AIComment.changeset(%{final_comment: final_comment})
        |> Repo.update()
    end
  end
end
