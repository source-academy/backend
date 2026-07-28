defmodule CadetWeb.Schemas.Device do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Device",
    description: "A device registered by the user",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Device id (unique to the user)"},
      type: %Schema{type: :string, description: "Device type"},
      title: %Schema{type: :string, description: "User-given device title"},
      secret: %Schema{type: :string, description: "Device unique secret"}
    },
    required: [:id, :type, :title, :secret]
  })
end

defmodule CadetWeb.Schemas.WebSocketEndpoint do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "WebSocketEndpoint",
    description: "A WebSocket endpoint for a device",
    type: :object,
    properties: %{
      endpoint: %Schema{type: :string, description: "Endpoint URL"},
      clientNamePrefix: %Schema{type: :string, description: "Client name prefix to use"},
      thingName: %Schema{type: :string, description: "Device name"}
    },
    required: [:endpoint, :clientNamePrefix, :thingName]
  })
end

defmodule CadetWeb.Schemas.RegisterDevicePayload do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RegisterDevicePayload",
    description: "Request body for registering a device",
    type: :object,
    properties: %{
      type: %Schema{type: :string, description: "Device type"},
      title: %Schema{type: :string, description: "User-given device title"},
      secret: %Schema{type: :string, description: "Device unique secret"}
    },
    required: [:type, :title, :secret]
  })
end

defmodule CadetWeb.Schemas.EditDevicePayload do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "EditDevicePayload",
    description: "Request body for editing a device",
    type: :object,
    properties: %{title: %Schema{type: :string, description: "User-given device title"}},
    required: [:title]
  })
end
