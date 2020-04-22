defmodule Cadet.Chapters.Chapter do
  @moduledoc """
  The Chapter entity for the default source version.
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  schema "chapters" do
    field(:chapterno, :integer, default: :public)
  end

  def changeset(chapter, params) do
    chapter
    |> cast(params, [:chapterno])
    |> validate_inclusion(:chapterno, 1..4)
  end
end
