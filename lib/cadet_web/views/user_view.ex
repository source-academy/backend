defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{user: user, grade: grade}) do
    %{name: user.name, role: user.role, grade: grade}
  end
end
