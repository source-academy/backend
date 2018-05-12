defmodule Cadet.Auth.ErrorHandler do
  @moduledoc """
  Handles authentication errors
  """
  use CadetWeb, :controller
  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    if type == :unauthenticated do
      conn |> redirect(to: session_path(conn, :new))
    else
      body = to_string(type)

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(401, body)
    end
  end
end
