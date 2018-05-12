defmodule CadetWeb.AdminController do
  use CadetWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end
end
