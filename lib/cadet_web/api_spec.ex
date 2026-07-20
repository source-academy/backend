defmodule CadetWeb.ApiSpec do
  @moduledoc """
  OpenAPI 3.0 specification for the Cadet API.

  The document is built entirely from code: paths are derived from
  `CadetWeb.Router` (only actions that declare an `operation` via
  `OpenApiSpex.ControllerSpecs` are included) and schemas are the
  `CadetWeb.Schemas.*` modules, resolved by `resolve_schema_modules/1`.

  Regenerate the on-disk spec with `mix openapi.spec.json` (see the
  `openapi.spec` mix alias) and validate it in tests via
  `test/cadet_web/api_spec_test.exs`.
  """
  @behaviour OpenApiSpex.OpenApi

  alias OpenApiSpex.{Components, Info, OpenApi, Paths, SecurityScheme, Server}
  alias CadetWeb.{Endpoint, Router}

  @impl OpenApiSpex.OpenApi
  def spec do
    %OpenApi{
      servers: [Server.from_endpoint(Endpoint)],
      info: %Info{
        title: "cadet",
        description: "The Source Academy backend API.",
        version: to_string(Application.spec(:cadet, :vsn))
      },
      # Paths are populated from the router; a controller only appears once it
      # declares operations via `use OpenApiSpex.ControllerSpecs`.
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          # JWT bearer token, sent in the `Authorization` header. Referenced by
          # operations as `security: [%{"JWT" => []}]`.
          "JWT" => %SecurityScheme{type: "http", scheme: "bearer", bearerFormat: "JWT"}
        }
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
