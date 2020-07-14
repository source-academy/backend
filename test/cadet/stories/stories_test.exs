defmodule Cadet.StoriesTest do
  alias Cadet.Stories.{Story, Stories}
  alias Cadet.Accounts.User

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
      assert_changeset_db(params, :valid)
    end

    test "invalid params", %{valid_params: params} do
      invalid_params = %{params | :open_at => Timex.shift(Timex.now(), years: 1)}
      assert_changeset_db(invalid_params, :invalid)
    end
  end

  describe "List stories" do
    test "All stories" do
      story1 = insert(:story)
      story2 = insert(:story)
      assert Stories.list_stories(%User{role: :staff}) == [story1, story2]
    end

    test "Only show published and open stories", %{valid_params: params} do
      one_week_ago = Timex.shift(Timex.now(), weeks: -1)

      insert(:story)
      insert(:story, %{params | :is_published => true})
      insert(:story, %{params | :open_at => one_week_ago})

      published_open_story =
        insert(:story, %{params | :is_published => true, :open_at => one_week_ago})

      assert Stories.list_stories(%User{role: :student}) == [published_open_story]
    end
  end

  describe "Create story" do
    test "create story", %{valid_params: params} do
      {:ok, story} = Stories.create_story(%User{role: :staff}, params)
      assert story |> Map.take(params |> Map.keys()) == params
    end
  end

  describe "Update story" do
    test "update story", %{updated_params: updated_params} do
      story = insert(:story)
      {:ok, story} = Stories.update_story(%User{role: :staff}, updated_params, story.id)

      assert story |> Map.take(updated_params |> Map.keys()) == updated_params
    end
  end

  describe "Delete story" do
    test "delete story" do
      story = insert(:story)
      {:ok, story} = Stories.delete_story(%User{role: :staff}, story.id)

      assert Repo.get(Story, story.id) == nil
    end
  end
end
