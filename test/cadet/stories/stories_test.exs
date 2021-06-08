defmodule Cadet.StoriesTest do
  alias Cadet.Stories.{Story, Stories}

  use Cadet.ChangesetCase, entity: Story

  setup do
    valid_params = %{
      open_at: Timex.shift(Timex.now(), days: 1),
      close_at: Timex.shift(Timex.now(), days: Enum.random(2..30)),
      is_published: false,
      filenames: ["mission-1.txt"],
      title: "Mission1",
      image_url: "http://example.com"
    }

    updated_params = %{
      title: "Mission2",
      image_url: "http://example.com/new"
    }

    {:ok, %{valid_params: valid_params, updated_params: updated_params}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      course = insert(:course)
      assert_changeset_db(Map.put(params, :course_id, course.id), :valid)
    end

    test "invalid params", %{valid_params: params} do
      invalid_params = %{params | :open_at => Timex.shift(Timex.now(), years: 1)}
      assert_changeset_db(invalid_params, :invalid)
    end
  end

  describe "List stories" do
    test "All stories from own course" do
      course = insert(:course)
      story1 = insert(:story, %{course: course}) |> remove_course_assoc()
      story2 = insert(:story, %{course: course}) |> remove_course_assoc()

      assert Stories.list_stories(insert(:course_registration, %{course: course, role: :staff})) ==
               [story1, story2]
    end

    test "Does not list stories from other courses" do
      course = insert(:course)
      insert(:story)
      story2 = insert(:story, %{course: course}) |> remove_course_assoc()

      assert Stories.list_stories(insert(:course_registration, %{course: course, role: :staff})) ==
               [story2]
    end

    test "Only show published and open stories", %{valid_params: params} do
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      course = insert(:course)
      insert(:story, %{course: course})
      insert(:story, %{Map.put(params, :course, course) | :is_published => true})
      insert(:story, %{Map.put(params, :course, course) | :open_at => one_week_ago})

      published_open_story =
        insert(
          :story,
          %{Map.put(params, :course, course) | :is_published => true, :open_at => one_week_ago}
        )
        |> remove_course_assoc()

      assert Stories.list_stories(insert(:course_registration, %{course: course, role: :student})) ==
               [published_open_story]
    end
  end

  describe "Create story" do
    test "create course story as staff", %{valid_params: params} do
      course_registration = insert(:course_registration, %{role: :staff})
      {:ok, story} = Stories.create_story(params, course_registration)
      params = Map.put(params, :course_id, course_registration.course_id)

      assert story |> Map.take(params |> Map.keys()) == params
    end

    test "students not allowed to create story", %{valid_params: params} do
      course_registration = insert(:course_registration, %{role: :student})

      assert {:error, {:forbidden, "User not allowed to manage stories"}} =
               Stories.create_story(params, course_registration)
    end
  end

  describe "Update story" do
    test "updating story as staff in own course", %{updated_params: updated_params} do
      course_registration = insert(:course_registration, %{role: :staff})
      story = insert(:story, %{course: course_registration.course})
      {:ok, updated_story} = Stories.update_story(updated_params, story.id, course_registration)
      updated_params = Map.put(updated_params, :course_id, course_registration.course_id)

      assert updated_story |> Map.take(updated_params |> Map.keys()) == updated_params
    end

    test "updating story that does not exist as staff", %{updated_params: updated_params} do
      course_registration = insert(:course_registration, %{role: :staff})
      story = insert(:story, %{course: course_registration.course})

      {:error, {:not_found, "Story not found"}} =
        Stories.update_story(updated_params, story.id + 1, course_registration)
    end

    test "staff fails to update story of another course", %{updated_params: updated_params} do
      course_registration = insert(:course_registration, %{role: :staff})
      story = insert(:story, %{course: build(:course)})

      assert {:error, {:forbidden, "User not allowed to manage stories from another course"}} =
               Stories.update_story(updated_params, story.id, course_registration)
    end

    test "student fails to update story of own course", %{updated_params: updated_params} do
      course_registration = insert(:course_registration, %{role: :student})
      story = insert(:story, %{course: course_registration.course})

      assert {:error, {:forbidden, "User not allowed to manage stories"}} =
               Stories.update_story(updated_params, story.id, course_registration)
    end
  end

  describe "Delete story" do
    test "staff deleting course story from own course" do
      course_registration = insert(:course_registration, %{role: :staff})
      story = insert(:story, %{course: course_registration.course})
      {:ok, story} = Stories.delete_story(story.id, course_registration)

      assert Repo.get(Story, story.id) == nil
    end

    test "staff deleting course story that does not exist" do
      course_registration = insert(:course_registration, %{role: :staff})
      story = insert(:story, %{course: course_registration.course})

      assert {:error, {:not_found, "Story not found"}} =
               Stories.delete_story(story.id + 1, course_registration)
    end

    test "staff fails to delete story from another course" do
      course_registration = insert(:course_registration, %{role: :staff})
      story = insert(:story, %{course: build(:course)})

      assert {:error, {:forbidden, "User not allowed to manage stories from another course"}} =
               Stories.delete_story(story.id, course_registration)
    end

    test "student fails to delete story from own course" do
      course_registration = insert(:course_registration, %{role: :student})
      story = insert(:story, %{course: course_registration.course})

      assert {:error, {:forbidden, "User not allowed to manage stories"}} =
               Stories.delete_story(story.id, course_registration)
    end
  end

  defp remove_course_assoc(story) do
    %{
      story
      | :course => %Ecto.Association.NotLoaded{
          __field__: :course,
          __owner__: story.__struct__,
          __cardinality__: :one
        }
    }
  end
end
