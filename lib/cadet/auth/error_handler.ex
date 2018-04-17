defmodule Cadet.Auth.ErrorHandler do
  @moduledoc """
  Handles authentication errors
  """
  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    body = to_string(type)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(401, body)
  end
end
