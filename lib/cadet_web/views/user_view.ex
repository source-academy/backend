defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{user: user, grade: grade, max_grade: max_grade, story: story}) do
    %{
      name: user.name,
      role: user.role,
      grade: grade,
      maxGrade: max_grade,
      story:
        transform_map_for_view(story, %{
          story: :story,
          playStory: :play_story?
        })
    }
  end
end
