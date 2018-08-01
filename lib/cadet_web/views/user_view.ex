defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{user: user, grade: grade, story: story}) do
    %{
      name: user.name,
      role: user.role,
      grade: grade,
      story:
        transform_map_for_view(story, %{
          story: :story,
          allAttempted: :all_attempted
        })
    }
  end
end
