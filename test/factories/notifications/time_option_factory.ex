defmodule Cadet.Notifications.TimeOptionFactory do
  @moduledoc """
  Factory for the TimeOption entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Notifications.TimeOption

      def time_option_factory do
        %TimeOption{
          is_default: false,
          minutes: 0,
          notification_config: build(:notification_config)
        }
      end
    end
  end
end
