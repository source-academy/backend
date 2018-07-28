defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{user: user, grade: grade, story: story}) do
    %{name: user.name, role: user.role, grade: grade, story: story}
  end
end
