defmodule CadetWeb.SettingsController do
  @moduledoc """
  Receives public requests involving Academy-wide configuration settings.
  """
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Settings

  @doc """
  Receives a /settings/sublanguage GET request.

  Returns the default Source sublanguage of the Playground.
  """
  def index(conn, _) do
    {:ok, sublanguage} = Settings.get_sublanguage()

    render(conn, "show.json", sublanguage: sublanguage)
  end

  swagger_path :index do
    get("/settings/sublanguage")

    summary("Retrieves the default Source sublanguage of the Playground")

    produces("application/json")

    response(200, "OK", Schema.ref(:Sublanguage))
  end

  def swagger_definitions do
    %{
      Sublanguage:
        swagger_schema do
          title("Sublanguage")

          properties do
            chapter(:integer, "Chapter number from 1 to 4", required: true, minimum: 1, maximum: 4)

            variant(:string, "Variant name, one of default/concurrent/gpu/lazy/non-det/wasm",
              required: true,
              enum: [:default, :concurrent, :gpu, :lazy, "non-det", :wasm]
            )
          end

          example(%{
            chapter: 1,
            variant: "default"
          })
        end
    }
  end
end
