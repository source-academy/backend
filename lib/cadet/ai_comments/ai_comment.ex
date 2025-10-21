defmodule Cadet.AIComments.AIComment do
  @moduledoc """
  Defines the schema and changeset for AI comments.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_comment_logs" do
    field(:raw_prompt, :string)
    field(:answers_json, :string)
    field(:response, :string)
    field(:error, :string)
    field(:comment_chosen, {:array, :string})
    field(:final_comment, :string)

    belongs_to(:submission, Cadet.Assessments.Submission)
    belongs_to(:question, Cadet.Assessments.Question)

    timestamps()
  end

  def changeset(ai_comment, attrs) do
    ai_comment
    |> cast(attrs, [
      :submission_id,
      :question_id,
      :raw_prompt,
      :answers_json,
      :response,
      :error,
      :comment_chosen,
      :final_comment
    ])
    |> validate_required([:submission_id, :question_id, :raw_prompt, :answers_json])
    |> foreign_key_constraint(:submission_id)
    |> foreign_key_constraint(:question_id)
  end
end
