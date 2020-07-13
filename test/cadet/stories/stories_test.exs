defmodule Cadet.StoriesTest do
  alias Cadet.Stories.{Story, Stories}
  alias Cadet.Accounts.User

  use Cadet.ChangesetCase, entity: Story

  setup do
    valid_params = %{
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), days: Enum.random(1..30)),
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
  end

  describe "List stories" do
    @tag authenticate: :staff
    test "list stories" do
      story1 = insert(:story)
      story2 = insert(:story)
      assert Stories.list_stories(%User{role: :staff}) == [story1, story2]
    end
  end

  describe "Create story" do
    @tag authenticate: :staff
    test "create story", %{valid_params: params} do
      {:ok, story} = Stories.create_story(%User{role: :staff}, params)
      assert story |> Map.take(params |> Map.keys()) == params
    end
  end

  describe "Update story" do
    @tag authenticate: :staff
    test "update story", %{updated_params: updated_params} do
      story = insert(:story)
      {:ok, story} = Stories.update_story(%User{role: :staff}, updated_params, story.id)

      assert story |> Map.take(updated_params |> Map.keys()) == updated_params
    end
  end

  describe "Delete story" do
    @tag authenticate: :staff
    test "delete story" do
      story = insert(:story)
      {:ok, story} = Stories.delete_story(%User{role: :staff}, story.id)

      assert Repo.get(Story, story.id) == nil
    end
  end
end
