defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{user: user, grade: grade, max_grade: max_grade, xp: xp, story: story, game_states: game_states}) do
    %{
      name: user.name,
      role: user.role,
      grade: grade,
      xp: xp,
      maxGrade: max_grade,
      story:
        transform_map_for_view(story, %{
          story: :story,
          playStory: :play_story?
        }),
      gameStates: game_states
    }
  end
end
