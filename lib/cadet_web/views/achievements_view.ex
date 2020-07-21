defmodule CadetWeb.AchievementsView do
  use CadetWeb, :view
  use Timex

  def render("index.json", %{achievements: achievements}) do
    render_many(achievements, CadetWeb.AchievementsView, "overview.json", as: :achievement)
  end

  def render("overview.json", %{achievement: achievement}) do
    transform_map_for_view(achievement, %{
      id: :id,
      title: :title,
      ability: :ability,
      release: &format_datetime(&1.open_at),
      deadline: &format_datetime(&1.close_at),
      isTask: :is_task,
      prerequisiteIds:
        &Enum.map(&1.prerequisites, fn prerequisite -> prerequisite.prerequisite_id end),
      cardTileUrl: :card_tile_url,
      position: :position,
      view:
        &%{
          canvasUrl: &1.canvas_url,
          description: &1.description,
          completionText: &1.completion_text
        },
      goals:
        &Enum.map(&1.goals, fn goal ->
          transform_map_for_view(goal, %{
            goalId: :order,
            goalText: :text,
            goalProgress: fn
              %{progress: [%{progress: progress} | _]} -> progress
              _ -> 0
            end,
            goalTarget: :target
          })
        end)
    })
  end
end
