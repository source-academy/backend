defmodule Cadet.Chapters.Chapter do
    @moduledoc """
    The Chapter entity the default chapter number.
    """
    use Cadet, :model
    use Arc.Ecto.Schema
  
    alias Cadet.Chapters
  
    schema "chapters" do
      field(:chapterno, :integer, default: :public)
    end
  
    def changeset(chapter, params) do
      chapter
      |> cast(params, [:chapterno])
    end
  end
  