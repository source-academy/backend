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
    field(:final_comment, :string)

    belongs_to(:answer, Cadet.Assessments.Answer)

    timestamps()
  end

  @required_fields ~w(answer_id raw_prompt answers_json)a
  @optional_fields ~w(response error final_comment)a

  def changeset(ai_comment, attrs) do
    ai_comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:answer_id)
  end
end
