defmodule CadetWeb.ChatView do
  use CadetWeb, :view

  def render("index.json", %{token: token}) do
    %{
      token: token
    }
  end
end
