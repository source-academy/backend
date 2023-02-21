defmodule Cadet.Notifications.NotificationPreference do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cadet.Notifications.NotificationConfig
  alias Cadet.Notifications.TimeOption
  alias Cadet.Accounts.CourseRegistration

  schema "notification_preferences" do
    field(:is_enabled, :boolean, default: false)

    belongs_to(:notification_config, NotificationConfig)
    belongs_to(:time_option, TimeOption)
    belongs_to(:course_reg, CourseRegistration)

    timestamps()
  end

  @doc false
  def changeset(notification_preference, attrs) do
    notification_preference
    |> cast(attrs, [:is_enabled])
    |> validate_required([:is_enabled])
  end
end
