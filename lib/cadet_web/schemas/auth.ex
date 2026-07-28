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

  # `refresh_token` is validated by the action (which returns its own error),
  # so it is not enforced here.
  OpenApiSpex.schema(%{
    title: "RefreshTokenRequest",
    description: "A refresh token",
    type: :object,
    properties: %{refresh_token: %Schema{type: :string, description: "Refresh token"}}
  })
end

defmodule CadetWeb.Schemas.LoginRequest do
  @moduledoc false
  require OpenApiSpex
  alias OpenApiSpex.Schema

  # The action validates required fields and returns its own errors.
  OpenApiSpex.schema(%{
    title: "LoginRequest",
    description: "OAuth2 login request",
    type: :object,
    properties: %{
      code: %Schema{type: :string, description: "OAuth2 code"},
      provider: %Schema{type: :string, description: "OAuth2 provider id"},
      client_id: %Schema{type: :string, description: "OAuth2 client id"},
      redirect_uri: %Schema{type: :string, description: "OAuth2 redirect URI"}
    }
  })
end
