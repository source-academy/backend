defmodule CadetWeb.SessionController do
  use CadetWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    redirect(conn, to: page_path(conn, :index))
  end

  def delete(conn, _params) do
    redirect(conn, to: session_path(conn, :new))
  end
end
