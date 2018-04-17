defmodule CadetWeb.Plug.CheckAdmin do
  @moduledoc """
  Checks whether :current_user is an admin.
  If the user is not an admin, the default HTTP 403 Forbidden page will be
  rendered.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    if conn.assigns[:current_user].role == :admin do
      conn
    else
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(:forbidden, "Not admin")
      |> halt()
    end
  end
end
