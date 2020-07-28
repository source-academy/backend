defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{
        user: user,
        grade: grade,
        max_grade: max_grade,
        xp: xp,
        story: story,
        game_states: game_states
      }) do
    %{
      userId: user.id,
      name: user.name,
      role: user.role,
      group:
        case user.group do
          nil -> nil
          _ -> user.group.name
        end,
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
