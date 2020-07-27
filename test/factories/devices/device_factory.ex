defmodule Cadet.Devices.DeviceFactory do
  @moduledoc """
  Factory(ies) for Cadet.Devices.Device entity
  """

  alias Cadet.Devices.Device

  defmacro __using__(_opts) do
    quote do
      def device_factory do
        %Device{
          secret: Faker.UUID.v4(),
          type: Enum.random(~w(esp32 ev3)),
          client_key: Faker.UUID.v4(),
          client_cert: Faker.UUID.v4()
        }
      end
    end
  end
end
