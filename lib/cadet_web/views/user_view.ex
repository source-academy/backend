defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("user_info.json", %{name: name, role: role, xp: xp}) do
    %{name: name, role: role, xp: xp}
  end
end
