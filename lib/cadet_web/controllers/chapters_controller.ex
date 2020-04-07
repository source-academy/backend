defmodule CadetWeb.ChaptersController do
    @moduledoc """
    Provides Chapter Number
    """
  
    use CadetWeb, :controller
    use PhoenixSwagger
  
    alias Cadet.Chapters
  
    def index(conn, _) do
      {:ok, chapter} = Chapters.get_chapter()
  
      render(
        conn,
        "show.json",
        chapter: chapter
      )
    end
  
    def update(conn, %{"id" => id, "chapterno" => chapterno}) do
      {:ok, chapter} = Chapters.update_chapter(chapterno)
  
      render(
        conn,
        "show.json",
        chapter: chapter
      )
    end
  end
  