defmodule CadetWeb.AuthView do
  use CadetWeb, :view

  def render("token.json", %{access_token: access_token, refresh_token: refresh_token}) do
    %{access_token: access_token, refresh_token: refresh_token}
  end
end
