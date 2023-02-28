defmodule Cadet.Notifications.TimeOption do
  @moduledoc """
  TimeOption entity for options course admins have created for notifications
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Cadet.Notifications.NotificationConfig

  schema "time_options" do
    field(:is_default, :boolean, default: false)
    field(:minutes, :integer, default: nil)

    belongs_to(:notification_config, NotificationConfig)

    timestamps()
  end

  @doc false
  def changeset(time_option, attrs) do
    time_option
    |> cast(attrs, [:minutes, :is_default])
  end
end
