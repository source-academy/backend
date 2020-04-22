defmodule Cadet.Chapters do
  @moduledoc """
  Chapters context contains the default source version.
  """
  use Cadet, [:context, :display]

  alias Cadet.Chapters.{Chapter}

  import Ecto.Query

  def get_chapter() do
    # Chapters table should only have 1 entry (as seeded). However, if table has more than 1 entry, the last created chapter entry will be returned.
    chapter = from(chapter in Chapter, limit: 1, order_by: [desc: chapter.id]) |> Repo.one()
    {:ok, chapter}
  end

  def update_chapter(chapterno) do
    {:ok, chapter} = get_chapter()
    changeset = Chapter.changeset(chapter, %{chapterno: chapterno})
    Repo.update!(changeset)
    get_chapter()
  end
end
