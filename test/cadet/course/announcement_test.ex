defmodule Cadet.Course.AnnouncementTest do
  use Cadet.DataCase

  alias Cadet.Course.Announcement

  @valid_changeset_params [
    %{title: "title", content: "Hello world", published: true}
  ]

  @invalid_changeset_params %{
    "empty title" => %{title: ""}
  }

  test "valid changeset" do
    @valid_changeset_params
    |> Enum.map(&User.changeset(%User{}, &1))
    |> Enum.each(&assert(&1.valid?()))
  end

  test "invalid changesets" do
    for {reason, param} <- @invalid_changeset_params do
      changeset = Announcement.changeset(%Announcement{}, param)
      refute(changeset.valid?(), reason)
    end
  end
end
