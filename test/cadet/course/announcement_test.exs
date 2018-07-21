defmodule Cadet.Course.AnnouncementTest do
  alias Cadet.Course.Announcement

  use Cadet.ChangesetCase, entity: Announcement

  describe "Changesets" do
    test "valid changesets" do
      assert_changeset(%{title: "title", content: "Hello world", published: true}, :valid)
    end

    test "invalid changeset" do
      assert_changeset(%{title: "", content: "Some content"}, :invalid)
    end
  end
end
