defmodule CadetWeb.ApiSpec.ErrorResponses do
  @moduledoc """
  Shared OpenAPI response definitions for the plain-text error bodies the API
  returns.

  Cadet renders errors as `text/plain` strings (see
  `CadetWeb.ControllerHelper.handle_standard_result/3`, the router's
  `assign_course`/`ensure_role` plugs, and per-action `send_resp`/`put_status`),
  not JSON envelopes. These helpers are meant to be spliced into a controller
  `operation`'s `responses:` list, keyed by the Plug status atom, e.g.

      responses: [
        ok: {"...", "application/json", MySchema},
        unauthorized: ErrorResponses.unauthorised(),
        forbidden: ErrorResponses.forbidden()
      ]
  """
  alias OpenApiSpex.Schema

  @string %Schema{type: :string, description: "Plain-text error message"}

  @spec unauthorised() :: {String.t(), String.t(), Schema.t()}
  def unauthorised, do: {"Unauthorised: missing or invalid token", "text/plain", @string}

  @spec forbidden() :: {String.t(), String.t(), Schema.t()}
  def forbidden, do: {"Forbidden: not enrolled or insufficient role", "text/plain", @string}

  @spec bad_request() :: {String.t(), String.t(), Schema.t()}
  def bad_request, do: {"Bad request: missing or invalid parameter(s)", "text/plain", @string}

  @spec not_found() :: {String.t(), String.t(), Schema.t()}
  def not_found, do: {"Not found", "text/plain", @string}

  @spec unprocessable() :: {String.t(), String.t(), Schema.t()}
  def unprocessable, do: {"Unprocessable entity", "text/plain", @string}

  @spec conflict() :: {String.t(), String.t(), Schema.t()}
  def conflict, do: {"Conflict", "text/plain", @string}

  @spec too_many_requests() :: {String.t(), String.t(), Schema.t()}
  def too_many_requests, do: {"Too many requests: rate limit exceeded", "text/plain", @string}

  @spec internal_server_error() :: {String.t(), String.t(), Schema.t()}
  def internal_server_error, do: {"Internal server error", "text/plain", @string}
end
