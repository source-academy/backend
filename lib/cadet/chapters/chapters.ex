defmodule Cadet.Chapters do
    @moduledoc """
    Chapters context contains the default chapter number.
    """
    use Cadet, [:context, :display]
  
    alias Cadet.Chapters.{Chapter}
  
    def get_chapter() do
      chapter = Repo.one(Chapter)
      {:ok, chapter}
    end
  
    def update_chapter(chapterno) do
      chapter = Repo.one(Chapter)
      changeset = Chapter.changeset(chapter, %{chapterno: chapterno})
      Repo.update!(changeset)
      {:ok, chapter}
    end
  end
  