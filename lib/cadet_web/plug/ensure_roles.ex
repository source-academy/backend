defmodule CadetWeb.Plug.EnsureRoles do
  @moduledoc """
  Ensures that :current_user's role is inside a list provided as option.
  If the user is not inside the list, HTTP 403 response will be sent.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, %{roles: roles}) do
    if conn.assigns[:current_user].role in roles do
      conn
    else
      body =
        roles
        |> Enum.map(&to_string/1)
        |> Enum.join("/")
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(:forbidden, "Not #{body}")
      |> halt()
    end
  end
end
