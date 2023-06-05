defmodule Cadet.Notifications.NotificationTypeFactory do
  @moduledoc """
  Factory for the NotificationType entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Notifications.NotificationType

      def notification_type_factory do
        %NotificationType{
          is_autopopulated: false,
          is_enabled: false,
          name: "Generic Notificaation Type",
          template_file_name: "generic_template_name"
        }
      end
    end
  end
end
