defmodule Cadet.Notifications.NotificationPreferenceFactory do
  @moduledoc """
  Factory for the NotificationPreference entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Notifications.NotificationPreference

      def notification_preference_factory do
        %NotificationPreference{
          is_enabled: false,
          notification_config: build(:notification_config),
          time_option: build(:time_option),
          course_reg: build(:course_registration)
        }
      end
    end
  end
end
