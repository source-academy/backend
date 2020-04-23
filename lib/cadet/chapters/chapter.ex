defmodule Cadet.Chapters.Chapter do
  @moduledoc """
  The Chapter entity for the default source version.
  """
  use Cadet, :model
  use Arc.Ecto.Schema

  schema "chapters" do
    field(:chapterno, :integer, default: :public)
    field(:variant, :string, default: :public)
  end

  @required_fields ~w(chapterno variant)a

  def changeset(chapter, params) do
    chapter
    |> cast(params, @required_fields)
    |> validate_inclusion(:chapterno, 1..4)
    |> validate_inclusion(:variant, ["default", "wasm", "lazy", "concurrent", "non-det"])
  end
end
