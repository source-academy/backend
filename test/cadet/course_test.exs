defmodule Cadet.CourseTest do
  use Cadet.DataCase

  alias Cadet.Course

  describe "Announcements" do
    test "create valid" do
      poster = insert(:user)
      assert {:ok, announcement} = Course.create_announcement(poster, %{
        title: "Test",
        content: "Some content"
      })
      assert announcement.title == "Test"
      assert announcement.content == "Some content"
    end

    test "create invalid" do
      poster = insert(:user)
      assert {:error, changeset} = Course.create_announcement(poster, %{
        title: "",
        content: "Some content"
      })
      assert errors_on(changeset) == %{title: ["can't be blank"]}
    end

    test "edit valid" do
      announcement = insert(:announcement)
      assert {:ok, announcement} = Course.edit_announcement(
        announcement.id,
        %{ title: "New title", pinned: true }
      )
      assert announcement.title == "New title"
      assert announcement.pinned 
    end

    test "get valid" do
      announcement = insert(:announcement)
      assert announcement == Course.get_announcement(announcement.id)
    end

    test "edit invalid" do
      announcement = insert(:announcement)
      assert {:error, changeset} = Course.edit_announcement(
        announcement.id,
        %{ title: "" }
      )
      assert errors_on(changeset) == %{title: ["can't be blank"]}
    end

    test "edit not found" do
      assert {:error, :not_found} = Course.edit_announcement(255, %{})
   end

    test "delete valid" do
      announcement = insert(:announcement)
      assert {:ok, _} = Course.delete_announcement(announcement.id)
    end

    test "delete not found" do
      assert {:error, :not_found} = Course.delete_announcement(255)
    end
  end
end
