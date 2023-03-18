defmodule Cadet.Notifications.NotificationConfig do
  @moduledoc """
  NotificationConfig entity to store course/assessment configuration for a specific notification type.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Cadet.Courses.{Course, AssessmentConfig}
  alias Cadet.Notifications.{NotificationType, TimeOption, NotificationPreference}

  schema "notification_configs" do
    field(:is_enabled, :boolean, default: false)

    belongs_to(:notification_type, NotificationType)
    belongs_to(:course, Course)
    belongs_to(:assessment_config, AssessmentConfig)

    has_many :time_options, TimeOption
    has_many :notification_preferences, NotificationPreference

    timestamps()
  end

  @doc false
  def changeset(notification_config, attrs) do
    notification_config
    |> cast(attrs, [:is_enabled, :notification_type_id, :course_id])
    |> validate_required([:notification_type_id, :course_id])
    |> prevent_nil_is_enabled()
  end

  defp prevent_nil_is_enabled(changeset = %{changes: %{is_enabled: is_enabled}})
       when is_nil(is_enabled),
       do: add_error(changeset, :full_name, "empty")

  defp prevent_nil_is_enabled(changeset),
    do: changeset
end
