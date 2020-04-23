defmodule Cadet.Chapters.ChapterTest do
  alias Cadet.Chapters.Chapter

  use Cadet.ChangesetCase, entity: Chapter

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          chapterno: 1,
          variant: "default"
        },
        :valid
      )
    end

    test "invalid changeset for chapterno" do
      assert_changeset(
        %{
          chapterno: 5,
          variant: "default"
        },
        :invalid
      )
    end

    test "invalid changeset for variant" do
      assert_changeset(
        %{
          chapterno: 1,
          variant: "wrong variant"
        },
        :invalid
      )
    end
  end
end
