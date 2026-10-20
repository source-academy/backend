defmodule Cadet.Chatbot.SlugTest do
  use ExUnit.Case, async: true

  alias Cadet.Chatbot.Slug

  describe "slugify/1" do
    test "lowercases and joins words with hyphens" do
      assert Slug.slugify("Lecture 1A Notes") == "lecture-1a-notes"
    end

    test "collapses runs of punctuation into a single hyphen" do
      assert Slug.slugify("L1A -- Recursion & Trees!") == "l1a-recursion-trees"
    end

    test "trims leading and trailing separators" do
      assert Slug.slugify("  ...Recursion...  ") == "recursion"
    end

    test "keeps digits" do
      assert Slug.slugify("Week 10 2026") == "week-10-2026"
    end

    # A title of nothing but punctuation, or one written entirely in a non-Latin script, slugifies
    # to the empty string. That would produce a blank doc_key and a bare "course-1/.pdf" S3 key,
    # so it falls back to a fixed word instead.
    test "falls back to 'document' when nothing survives" do
      assert Slug.slugify("!!!") == "document"
      assert Slug.slugify("") == "document"
      assert Slug.slugify("   ") == "document"
      assert Slug.slugify("讲义") == "document"
    end
  end

  describe "unique/2" do
    test "returns the base untouched when it is free" do
      assert Slug.unique("l1a", fn _ -> false end) == "l1a"
    end

    test "appends -1 for the first collision" do
      assert Slug.unique("l1a", &(&1 == "l1a")) == "l1a-1"
    end

    # Two documents titled the same, uploaded a third time, must not loop forever on -1.
    test "keeps counting past an occupied suffix" do
      taken = MapSet.new(["l1a", "l1a-1", "l1a-2"])

      assert Slug.unique("l1a", &MapSet.member?(taken, &1)) == "l1a-3"
    end

    test "asks about the base before any suffix" do
      parent = self()

      Slug.unique("l1a", fn candidate ->
        send(parent, {:asked, candidate})
        candidate != "l1a-1"
      end)

      assert_receive {:asked, "l1a"}
      assert_receive {:asked, "l1a-1"}
    end
  end
end
