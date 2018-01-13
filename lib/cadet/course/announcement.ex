defmodule Cadet.Course.Announcement do
  @moduledoc """
  The Announcement entity represents an announcement.
  """
  use Cadet, :model

  alias Cadet.Accounts.User

  schema "announcements" do
    field(:title, :string)
    field(:content, :string)
    field(:pinned, :boolean, default: false)
    field(:published, :boolean, default: false)

    belongs_to(:poster, User)

    timestamps()
  end

  @required_fields ~w(title)a
  @optional_fields ~w(content pinned published)a

  def changeset(announcement, attrs \\ %{}) do
    announcement
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
  end
end
