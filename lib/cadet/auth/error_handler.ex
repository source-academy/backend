defmodule Cadet.Auth.ErrorHandler do
  @moduledoc """
  Handles authentication errors
  """
  import Phoenix.Controller, only: [redirect: 2]
  import CadetWeb.Router.Helpers, only: [session_path: 2]
  import Plug.Conn

  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> put_status(401)
    |> redirect(to: session_path(conn, :new))
  end
end
