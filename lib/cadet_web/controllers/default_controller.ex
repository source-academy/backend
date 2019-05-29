defmodule CadetWeb.DefaultController do
  use CadetWeb, :controller

  def index(conn, _) do
    text(conn, "Welcome to the Source Academy Backend!")
  end
end
