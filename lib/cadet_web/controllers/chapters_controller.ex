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

  def update(conn, %{"id" => _id, "chapterno" => chapterno, "variant" => variant}) do
    {:ok, chapter} = Chapters.update_chapter(chapterno, variant)

    render(
      conn,
      "show.json",
      chapter: chapter
    )
  end
end
