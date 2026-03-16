defmodule Cadet.AIComments.AICommentVersion do
  @moduledoc """
  Defines the schema and changeset for AI comment versions.
  Tracks per-comment edits made by tutors.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_comment_versions" do
    field(:comment_index, :integer)
    field(:version_number, :integer)
    field(:content, :string)

    belongs_to(:ai_comment, Cadet.AIComments.AIComment)
    belongs_to(:editor, Cadet.Accounts.User, foreign_key: :editor_id)

    timestamps()
  end

  @required_fields ~w(ai_comment_id comment_index version_number content)a
  @optional_fields ~w(editor_id)a

  def changeset(version, attrs) do
    version
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:ai_comment_id)
    |> foreign_key_constraint(:editor_id)
    |> unique_constraint([:ai_comment_id, :comment_index, :version_number])
  end
end
