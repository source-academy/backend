defmodule Cadet.Settings.SublanguageTest do
  alias Cadet.Settings.Sublanguage

  use Cadet.ChangesetCase, entity: Sublanguage

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{chapter: 1, variant: "wasm"}, :valid)
      assert_changeset(%{chapter: 2, variant: "lazy"}, :valid)
      assert_changeset(%{chapter: 3, variant: "non-det"}, :valid)
      assert_changeset(%{chapter: 4, variant: "default"}, :valid)
    end

    test "invalid changeset missing required params" do
      assert_changeset(%{chapter: 2}, :invalid)
    end

    test "invalid changeset with invalid chapter" do
      assert_changeset(%{chapter: 5, variant: "default"}, :invalid)
    end

    test "invalid changeset with invalid variant" do
      assert_changeset(%{chapter: Enum.random(1..4), variant: "error"}, :invalid)
    end

    test "invalid changeset with invalid chapter-variant combination" do
      assert_changeset(%{chapter: 4, variant: "lazy"}, :invalid)
    end
  end
end
