defmodule CadetWeb.AdminUserView do
  use CadetWeb, :view

  def render("users.json", %{users: users}) do
    render_many(users, CadetWeb.AdminUserView, "user.json", as: :user)
  end

  def render("user.json", %{user: user}) do
    %{
      userId: user.id,
      name: user.name,
      role: user.role,
      group:
        case user.group do
          nil -> nil
          _ -> user.group.name
        end
    }
  end
end
