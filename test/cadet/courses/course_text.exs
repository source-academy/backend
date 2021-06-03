defmodule Cadet.Courses.CourseTest do
  alias Cadet.Courses.Course

  use Cadet.ChangesetCase, entity: Course

  describe "Sublanguage Changesets" do
    test "valid changesets" do
      assert_changeset(%{source_chapter: 1, source_variant: "wasm"}, :valid, :sublanguage_changeset)
      assert_changeset(%{source_chapter: 2, source_variant: "lazy"}, :valid, :sublanguage_changeset)
      assert_changeset(%{source_chapter: 3, source_variant: "non-det"}, :valid, :sublanguage_changeset)
      assert_changeset(%{source_chapter: 4, source_variant: "default"}, :valid, :sublanguage_changeset)
    end

    test "invalid changeset missing required params" do
      assert_changeset(%{source_chapter: 2}, :invalid, :sublanguage_changeset)
    end

    test "invalid changeset with invalid chapter" do
      assert_changeset(%{source_chapter: 5, source_variant: "default"}, :invalid, :sublanguage_changeset)
    end

    test "invalid changeset with invalid variant" do
      assert_changeset(%{source_chapter: Enum.random(1..4), source_variant: "error"}, :invalid, :sublanguage_changeset)
    end

    test "invalid changeset with invalid chapter-variant combination" do
      assert_changeset(%{source_chapter: 4, source_variant: "lazy"}, :invalid, :sublanguage_changeset)
    end
  end
end
