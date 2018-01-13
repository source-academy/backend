defmodule CadetWeb.Plug.AssignCurrentUser do
  @moduledoc """
  A plug that assign :current_user to currently logged in user
  """
  alias Cadet.Auth.Guardian.Plug, as: GPlug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = GPlug.current_resource(conn)

    if current_user != nil do
      assign(conn, :current_user, current_user)
    else
      conn
    end
  end
end
