defmodule Cadet.ChaptersTest do
  use Cadet.DataCase

  alias Cadet.Chapters

  test "get chapter" do
    insert(:chapter)
    {:ok, chapter} = Chapters.get_chapter()
    assert chapter.chapterno == 1
  end

  test "update chapter" do
    insert(:chapter)
    no = Enum.random(1..4)
    {:ok, chapter} = Chapters.update_chapter(no)
    assert chapter.chapterno == no
  end
end
