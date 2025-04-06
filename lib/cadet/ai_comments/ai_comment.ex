defmodule Cadet.AIComments.AIComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_comment_logs" do
    field :submission_id, :integer
    field :question_id, :integer
    field :raw_prompt, :string
    field :answers_json, :string
    field :response, :string
    field :error, :string
    field :comment_chosen, {:array, :string}
    field :final_comment, :string

    timestamps()
  end

  def changeset(ai_comment, attrs) do
    ai_comment
    |> cast(attrs, [:submission_id, :question_id, :raw_prompt, :answers_json, :response, :error, :comment_chosen, :final_comment])
    |> validate_required([:submission_id, :question_id, :raw_prompt, :answers_json])
  end
end
