defmodule CadetWeb.PageController do
  use CadetWeb, :controller

  alias Cadet.Auth.Guardian

  def index(conn, _params) do
    if Guardian.Plug.authenticated?(conn) do
      render(conn, "index.html")
    else
      conn |> redirect(to: session_path(conn, :new))
    end
  end
end
