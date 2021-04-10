defmodule CadetWeb.AdminSettingsController do
  @moduledoc """
  Receives authorized requests involving Academy-wide configuration settings.
  """
  use CadetWeb, :controller

  use PhoenixSwagger

  alias Cadet.Settings

  @doc """
  Receives a /settings/sublanguage PUT request with valid attributes.

  Overrides the stored default Source sublanguage of the Playground.
  """
  def update(conn, %{"chapter" => chapter, "variant" => variant}) do
    case Settings.update_sublanguage(chapter, variant) do
      {:ok, _} ->
        text(conn, "OK")

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid parameter(s)")
    end
  end

  def update(conn, _) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  swagger_path :update do
    put("/admin/settings/sublanguage")

    summary("Updates the default Source sublanguage of the Playground")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      sublanguage(:body, Schema.ref(:AdminSublanguage), "sublanguage object", required: true)
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(403, "Forbidden")
  end

  def swagger_definitions do
    %{
      AdminSublanguage:
        swagger_schema do
          title("AdminSublanguage")

          properties do
            chapter(:integer, "Chapter number from 1 to 4", required: true, minimum: 1, maximum: 4)

            variant(:string, "Variant name",
              required: true,
              enum: [:default, :concurrent, :gpu, :lazy, "non-det", :wasm]
            )
          end

          example(%{
            chapter: 2,
            variant: "lazy"
          })
        end
    }
  end
end
