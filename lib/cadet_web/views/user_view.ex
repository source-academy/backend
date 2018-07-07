defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{user: user, xp: xp}) do
    %{name: user.name, role: user.role, xp: xp}
  end
end
