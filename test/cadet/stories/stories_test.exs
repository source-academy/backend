defmodule Cadet.StoriesTest do
  alias Cadet.Stories.{Story, Stories}

  use Cadet.ChangesetCase, entity: Story

  setup do
    staff = insert(:user, %{role: :staff})
    student = insert(:user, %{role: :student})

    valid_params = %{
      open_at: Timex.now(),
      close_at: Timex.shift(Timex.now(), years: 2),
      filenames: ["mission-1.txt"],
      title: "Mission1",
      image_url: "http://example.com"
    }

    updated_params = %{
      title: "Mission2",
      image_url: "http://example.com/new"
    }

    {:ok,
     %{valid_params: valid_params, updated_params: updated_params, staff: staff, student: student}}
  end

  describe "Changesets" do
    test "valid params", %{valid_params: params} do
      assert_changeset_db(params, :valid)
    end
  end

  describe "Create story" do
    @tag authenticate: :staff
    test "create story", %{valid_params: params, staff: staff} do
      {:ok, story} = Stories.create_story(staff, params)
      assert story |> Map.take(params |> Map.keys()) == params
    end
  end

  describe "Update story" do
    @tag authenticate: :staff
    test "update story", %{valid_params: params, staff: staff, updated_params: updated_params} do
      story = insert(:story, params)
      {:ok, story} = Stories.update_story(staff, updated_params, story.id)

      assert story |> Map.take(updated_params |> Map.keys()) == updated_params
    end
  end
end
