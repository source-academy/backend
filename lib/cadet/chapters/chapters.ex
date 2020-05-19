defmodule Cadet.Chapters do
  @moduledoc """
  Chapters context contains the default source version.
  """
  use Cadet, [:context, :display]

  alias Cadet.Chapters.Chapter

  import Ecto.Query

  def get_chapter do
    # Chapters table should only have 1 entry (as seeded).
    # However, if table has more than 1 entry, the last created chapter entry will be returned.
    {:ok, retrieve_chapter() || %Chapter{chapterno: 1, variant: "default"}}
  end

  def update_chapter(chapterno, variant) do
    new_chapter =
      case retrieve_chapter() do
        nil ->
          %Chapter{}
          |> Chapter.changeset(%{chapterno: chapterno, variant: variant})
          |> Repo.insert!()

        chapter ->
          chapter
          |> Chapter.changeset(%{chapterno: chapterno, variant: variant})
          |> Repo.update!()
      end

    {:ok, new_chapter}
  end

  defp retrieve_chapter do
    Chapter |> order_by(desc: :id) |> limit(1) |> Repo.one()
  end
end
