defmodule Cadet.Notifications.TimeOption do
  @moduledoc """
  TimeOption entity for options course admins have created for notifications
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Cadet.Notifications.NotificationConfig

  schema "time_options" do
    field(:is_default, :boolean, default: false)
    field(:minutes, :integer)

    belongs_to(:notification_config, NotificationConfig)

    timestamps()
  end

  @doc false
  def changeset(time_option, attrs) do
    time_option
    |> cast(attrs, [:minutes, :is_default, :notification_config_id])
    |> validate_required([:minutes, :notification_config_id])
    |> validate_number(:minutes, greater_than_or_equal_to: 0)
    |> unique_constraint([:minutes, :notification_config_id], name: :unique_time_options)
    |> foreign_key_constraint(:notification_config_id)
  end
end
