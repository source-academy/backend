defmodule CadetWeb.Plug.CheckAdmin do
  @moduledoc """
  A plug that checks whether :current_user is an admin
  """

  import Plug.Conn

  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _) do
    if conn.assigns[:current_user] != nil && conn.assigns[:current_user].role == :admin do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> render(CadetWeb.ErrorView, "403.html")
      |> halt()
    end
  end
end
