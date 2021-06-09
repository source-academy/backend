defmodule CadetWeb.AdminUserView do
  use CadetWeb, :view

  def render("users.json", %{users: users}) do
    render_many(users, CadetWeb.AdminUserView, "cr.json", as: :cr)
  end

  def render("cr.json", %{cr: cr}) do
    %{
      crId: cr.id,
      course_id: cr.course_id,
      name: cr.user.name,
      role: cr.role,
      group:
        case cr.group do
          nil -> nil
          _ -> cr.group.name
        end
    }
  end
end
