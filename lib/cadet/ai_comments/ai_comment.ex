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

    belongs_to(:answer, Cadet.Assessments.Answer)

    timestamps()
  end

  def changeset(ai_comment, attrs) do
    ai_comment
    |> cast(attrs, [
      :answer_id,
      :raw_prompt,
      :answers_json,
      :response,
      :error,
      :comment_chosen,
      :final_comment
    ])
    |> validate_required([:answer_id, :raw_prompt, :answers_json])
    |> foreign_key_constraint(:answer_id)
  end
end
