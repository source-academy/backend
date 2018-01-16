defmodule Cadet.CourseTest do
  use Cadet.DataCase

  alias Cadet.Course

  describe "Announcements" do
    test "create valid" do
      poster = insert(:user)

      assert {:ok, announcement} =
               Course.create_announcement(poster, %{
                 title: "Test",
                 content: "Some content"
               })

      assert announcement.title == "Test"
      assert announcement.content == "Some content"
    end

    test "create invalid" do
      poster = insert(:user)

      assert {:error, changeset} =
               Course.create_announcement(poster, %{
                 title: "",
                 content: "Some content"
               })

      assert errors_on(changeset) == %{title: ["can't be blank"]}
    end

    test "edit valid" do
      announcement = insert(:announcement)

      assert {:ok, announcement} =
               Course.edit_announcement(announcement.id, %{title: "New title", pinned: true})

      assert announcement.title == "New title"
      assert announcement.pinned
    end

    test "get valid" do
      announcement = insert(:announcement)
      assert announcement == Course.get_announcement(announcement.id)
    end

    test "edit invalid" do
      announcement = insert(:announcement)
      assert {:error, changeset} = Course.edit_announcement(announcement.id, %{title: ""})
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

  describe "Points" do
    test "give manual xp valid" do
      staff = insert(:user, %{role: :staff})
      student = insert(:user)

      result =
        Course.give_manual_xp(staff, student, %{
          reason: "DG XP Week 4",
          amount: 100
        })

      assert {:ok, point} = result
      assert point.amount == 100
    end

    test "give manual xp invalid" do
      staff = insert(:user, %{role: :staff})
      student = insert(:user)

      result =
        Course.give_manual_xp(staff, student, %{
          reason: "DG XP Week 4",
          amount: -100
        })

      assert {:error, changeset} = result
      assert errors_on(changeset) == %{amount: ["must be greater than 0"]}
    end

    test "give manual xp not staff" do
      student = insert(:user)

      result =
        Course.give_manual_xp(student, student, %{
          reason: "DG XP Week 4",
          amount: 100
        })

      assert {:error, :insufficient_privileges} = result
    end

    test "delete manual xp" do
      point = insert(:point)
      student = insert(:user)
      staff = insert(:user, %{role: :staff})
      admin = insert(:user, %{role: :admin})
      assert {:error, :not_found} = Course.delete_manual_xp(student, 200)
      assert {:error, :insufficient_privileges} = Course.delete_manual_xp(staff, point.id)
      assert {:error, :insufficient_privileges} = Course.delete_manual_xp(student, point.id)
      assert {:ok, _} = Course.delete_manual_xp(point.given_by, point.id)
      point = insert(:point)
      assert {:ok, _} = Course.delete_manual_xp(admin, point.id)
    end
  end
end
