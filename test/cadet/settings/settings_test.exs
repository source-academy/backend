defmodule Cadet.SettingsTest do
  use Cadet.DataCase

  alias Cadet.Settings

  test "get sublanguage" do
    insert(:sublanguage, %{chapter: 3, variant: "non-det"})
    {:ok, sublanguage} = Settings.get_sublanguage()
    assert sublanguage.chapter == 3
    assert sublanguage.variant == "non-det"
  end

  test "get sublanguage default" do
    {:ok, sublanguage} = Settings.get_sublanguage()
    assert sublanguage.chapter == 1
    assert sublanguage.variant == "default"
  end

  test "update sublanguage" do
    insert(:sublanguage)
    new_chapter = Enum.random(1..4)
    {:ok, sublanguage} = Settings.update_sublanguage(new_chapter, "default")
    assert sublanguage.chapter == new_chapter
    assert sublanguage.variant == "default"
  end

  test "update chapter with no existing entry" do
    new_chapter = Enum.random(1..4)
    {:ok, sublanguage} = Settings.update_sublanguage(new_chapter, "default")
    assert sublanguage.chapter == new_chapter
    assert sublanguage.variant == "default"
  end
end
