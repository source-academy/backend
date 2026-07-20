defmodule CadetWeb.Schemas.Tokens do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Tokens",
    description: "Access and refresh tokens",
    type: :object,
    properties: %{
      access_token: %Schema{type: :string, description: "Access token (TTL 1 hour)"},
      refresh_token: %Schema{type: :string, description: "Refresh token (TTL 1 week)"}
    },
    required: [:access_token, :refresh_token]
  })
end

defmodule CadetWeb.Schemas.RefreshTokenRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RefreshTokenRequest",
    description: "A refresh token",
    type: :object,
    properties: %{refresh_token: %Schema{type: :string, description: "Refresh token"}},
    required: [:refresh_token]
  })
end
