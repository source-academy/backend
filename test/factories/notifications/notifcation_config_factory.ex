defmodule Cadet.Notifications.NotificationConfigFactory do
  @moduledoc """
  Factory for the NotificationConfig entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Notifications.NotificationConfig

      def notification_config_factory do
        %NotificationConfig{
          is_enabled: false,
          notification_type: build(:notification_type),
          course: build(:course),
          assessment_config: build(:assessment_config)
        }
      end
    end
  end
end
