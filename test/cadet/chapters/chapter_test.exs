defmodule Cadet.Chapters.ChapterTest do
  alias Cadet.Chapters.Chapter

  use Cadet.ChangesetCase, entity: Chapter

  describe "Changesets" do
    test "valid changeset" do
      assert_changeset(
        %{
          chapterno: Enum.random(1..4)
        },
        :valid
      )
    end

    test "invalid changeset" do
      assert_changeset(
        %{
          chapterno: 5
        },
        :invalid
      )
    end
  end
end
