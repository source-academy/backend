defmodule Cadet.SettingsTest do
  use Cadet.DataCase

  alias Cadet.Settings

  describe "get sublanguage" do
    test "succeeds" do
      insert(:sublanguage, %{chapter: 3, variant: "concurrent"})
      {:ok, sublanguage} = Settings.get_sublanguage()
      assert sublanguage.chapter == 3
      assert sublanguage.variant == "concurrent"
    end

    test "returns default if no existing entry exists" do
      {:ok, sublanguage} = Settings.get_sublanguage()
      assert sublanguage.chapter == 1
      assert sublanguage.variant == "default"
    end
  end

  describe "update sublanguage" do
    test "succeeds" do
      insert(:sublanguage)
      new_chapter = Enum.random(1..4)
      {:ok, sublanguage} = Settings.update_sublanguage(new_chapter, "default")
      assert sublanguage.chapter == new_chapter
      assert sublanguage.variant == "default"
    end

    test "succeeds if no existing entry exists" do
      new_chapter = Enum.random(1..4)
      {:ok, sublanguage} = Settings.update_sublanguage(new_chapter, "default")
      assert sublanguage.chapter == new_chapter
      assert sublanguage.variant == "default"
    end

    test "returns with error for failed updates" do
      assert {:error, changeset} = Settings.update_sublanguage(0, "default")
      assert %{chapter: ["is invalid"]} = errors_on(changeset)

      assert {:error, changeset} = Settings.update_sublanguage(2, "gpu")
      assert %{variant: ["is invalid"]} = errors_on(changeset)
    end
  end
end
