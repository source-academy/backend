defmodule Cadet.Auth.Pipeline do
  @moduledoc """
  Pipeline to verify Guardian JWT token session and header
  """
  use Guardian.Plug.Pipeline,
    otp_app: :cadet,
    error_handler: Cadet.Auth.ErrorHandler,
    module: Cadet.Auth.Guardian

  # If there is a session token, validate it
  plug(Guardian.Plug.VerifySession, claims: %{"typ" => "access"})
  # If there is an authorization header, validate it
  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  # Load the user if either of the verifications worked
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
