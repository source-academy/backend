defmodule CadetWeb.Plugs.OpenApiErrorRenderer do
  @moduledoc """
  Custom error renderer for `OpenApiSpex.Plug.CastAndValidate`.

  Preserves Cadet's existing error contract: when an incoming request fails
  schema validation, respond with **HTTP 400** and a plain-text body, matching
  the `"Missing or invalid parameter(s)"` convention most actions already use
  for malformed requests — rather than open_api_spex's default `422` JSON.

  This keeps request validation backwards-compatible for API consumers (the
  status and shape are unchanged) while adding the guarantee that malformed
  requests are rejected before reaching the controller action.
  """
  @behaviour Plug

  import Plug.Conn

  @message "Missing or invalid parameter(s)"

  @impl Plug
  def init(errors), do: errors

  @impl Plug
  def call(conn, _errors) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, @message)
  end
end
