defmodule CadetWeb.AdminUserView do
  use CadetWeb, :view

  def render("users.json", %{users: users}) do
    render_many(users, CadetWeb.AdminUserView, "cr.json", as: :cr)
  end

  def render("get_students.json", %{users: users}) do
    render_many(users, CadetWeb.AdminUserView, "students.json", as: :students)
  end

  def render("cr.json", %{cr: cr}) do
    %{
      courseRegId: cr.id,
      course_id: cr.course_id,
      name: cr.user.name,
      provider: cr.user.provider,
      username: cr.user.username,
      role: cr.role,
      group:
        case cr.group do
          nil -> nil
          _ -> cr.group.name
        end
    }
  end

  def render("students.json", %{students: students}) do
    %{
      userId: students.id,
      name: students.user.name,
      username: students.user.username
    }
  end
end
