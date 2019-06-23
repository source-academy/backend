defmodule CadetWeb.ChatView do
  use CadetWeb, :view

  def render("index.json", %{access_token: token, expires_in: ttl}) do
    %{
      access_token: token,
      expires_in: ttl
    }
  end
end
