defmodule Cadet.Accounts.NotificationFactory do
  @moduledoc """
  Factory for the Notification entity
  """

  defmacro __using__(_opts) do
    quote do
      alias Cadet.Accounts.Notification

      def notification_factory do
        valid_types = [:new]

        %Notification{
          type: Enum.random(valid_types),
          read: Enum.random([true, false])
        }
      end
    end
  end
end
