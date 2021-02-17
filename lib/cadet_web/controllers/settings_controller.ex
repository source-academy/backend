defmodule CadetWeb.SettingsController do
  @moduledoc """
  Receives all requests involving Academy-wide configuration settings.
  """
  use CadetWeb, :controller
  use PhoenixSwagger

  alias Cadet.Settings

  @set_sublanguage_roles ~w(staff admin)a

  @doc """
  Receives a /settings/sublanguage GET request.

  Returns the default Source sublanguage of the Playground.
  """
  def index(conn, _) do
    {:ok, sublanguage} = Settings.get_sublanguage()

    render(conn, "show.json", sublanguage: sublanguage)
  end

  @doc """
  Receives a /settings/sublanguage PUT request with valid attributes.

  Overrides the stored default Source sublanguage of the Playground.
  """
  def update(conn, %{"chapter" => chapter, "variant" => variant}) do
    role = conn.assigns[:current_user].role

    if role in @set_sublanguage_roles do
      case Settings.update_sublanguage(chapter, variant) do
        {:ok, _} ->
          text(conn, "OK")

        {:error, _} ->
          conn
          |> put_status(:bad_request)
          |> text("Invalid parameter(s)")
      end
    else
      conn
      |> put_status(:forbidden)
      |> text("User not allowed to set default Playground sublanguage.")
    end
  end

  def update(conn, _) do
    send_resp(conn, :bad_request, "Missing parameter(s)")
  end

  swagger_path :index do
    get("/settings/sublanguage")

    summary("Retrieves the default Source sublanguage of the Playground.")

    produces("application/json")

    response(200, "OK", Schema.ref(:Sublanguage))
  end

  swagger_path :update do
    put("/settings/sublanguage")

    summary("Updates the default Source sublanguage of the Playground.")

    security([%{JWT: []}])

    consumes("application/json")

    parameters do
      sublanguage(:body, Schema.ref(:Sublanguage), "sublanguage object", required: true)
    end

    response(200, "OK")
    response(400, "Missing or invalid parameter(s)")
    response(401, "Unauthorised")
    response(403, "User not allowed to set default Playground sublanguage.")
  end

  def swagger_definitions do
    %{
      Sublanguage:
        swagger_schema do
          title("Sublanguage")

          properties do
            chapter(:integer, "Chapter number from 1 to 4", required: true, minimum: 1, maximum: 4)

            variant(:string, "Variant name, one of default/concurrent/gpu/lazy/non-det/wasm",
              required: true
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
