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
      story1 = :story |> insert(%{course: course}) |> remove_course_assoc()
      story2 = :story |> insert(%{course: course}) |> remove_course_assoc()

      assert Stories.list_stories(course.id, true) ==
               [story1, story2]
    end

    test "Does not list stories from other courses" do
      course = insert(:course)
      insert(:story)
      story2 = :story |> insert(%{course: course}) |> remove_course_assoc()

      assert Stories.list_stories(course.id, true) ==
               [story2]
    end

    test "Only show published and open stories", %{valid_params: params} do
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      course = insert(:course)
      insert(:story, %{course: course})
      insert(:story, %{Map.put(params, :course, course) | :is_published => true})
      insert(:story, %{Map.put(params, :course, course) | :open_at => one_week_ago})

      published_open_story =
        :story
        |> insert(%{
          Map.put(params, :course, course)
          | :is_published => true,
            :open_at => one_week_ago
        })
        |> remove_course_assoc()

      assert Stories.list_stories(course.id, false) ==
               [published_open_story]
    end
  end

  describe "Create story" do
    test "create course story", %{valid_params: params} do
      course = insert(:course)
      {:ok, story} = Stories.create_story(params, course.id)
      params = Map.put(params, :course_id, course.id)

      assert story |> Map.take(params |> Map.keys()) == params
    end
  end

  describe "Update story" do
    test "updating story as staff in own course", %{updated_params: updated_params} do
      course = insert(:course)
      story = insert(:story, %{course: course})
      {:ok, updated_story} = Stories.update_story(updated_params, story.id, course.id)
      updated_params = Map.put(updated_params, :course_id, course.id)

      assert updated_story |> Map.take(updated_params |> Map.keys()) == updated_params
    end

    test "updating story that does not exist as staff", %{updated_params: updated_params} do
      course = insert(:course)
      story = insert(:story, %{course: course})

      {:error, {:not_found, "Story not found"}} =
        Stories.update_story(updated_params, story.id + 1, course.id)
    end

    test "staff fails to update story of another course", %{updated_params: updated_params} do
      course = insert(:course)
      story = insert(:story, %{course: build(:course)})

      assert {:error, {:forbidden, "User not allowed to manage stories from another course"}} =
               Stories.update_story(updated_params, story.id, course.id)
    end
  end

  describe "Delete story" do
    test "staff deleting course story from own course" do
      course = insert(:course)
      story = insert(:story, %{course: course})
      {:ok, story} = Stories.delete_story(story.id, course.id)

      assert Repo.get(Story, story.id) == nil
    end

    test "staff deleting course story that does not exist" do
      course = insert(:course)
      story = insert(:story, %{course: course})

      assert {:error, {:not_found, "Story not found"}} =
               Stories.delete_story(story.id + 1, course.id)
    end

    test "staff fails to delete story from another course" do
      course = insert(:course)
      story = insert(:story, %{course: build(:course)})

      assert {:error, {:forbidden, "User not allowed to manage stories from another course"}} =
               Stories.delete_story(story.id, course.id)
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
