defmodule Cadet.Auth.ErrorHandler do
  @moduledoc """
  Handles authentication errors
  """
  import Plug.Conn

  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> send_resp(401, "Unauthorised")
  end
end
