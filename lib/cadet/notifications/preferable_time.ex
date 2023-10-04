defmodule Cadet.Notifications.PreferableTime do
  @moduledoc """
  PreferableTime entity for recipients to set their preferable notification times.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Cadet.Notifications.NotificationPreference

  schema ":preferable_times" do
    field(:minutes, :integer)

    belongs_to(:notification_preferences, NotificationPreference)

    timestamps()
  end

  @doc false
  def changeset(preferable_time, attrs) do
    preferable_time
    |> cast(attrs, [:minutes, :notification_preference_id])
    |> validate_required([:minutes, :notification_preference_id])
    |> validate_number(:minutes, greater_than_or_equal_to: 0)
    |> unique_constraint([:minutes, :notification_preference_id], name: :unique_preferable_times)
    |> foreign_key_constraint(:notification_preference_id)
  end
end
