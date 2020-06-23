defmodule CadetWeb.AchievementsView do
  
  use CadetWeb, :view
  use Timex

  import CadetWeb.AssessmentsHelpers

  def render("index.json", %{achievements: achievements}) do
    render_many(achievements, CadetWeb.AchievementsView, "overview.json", as: :achievement)
  end

  def render("overview.json", %{achievement: achievement}) do
    transform_map_for_view(achievement, %{
      id: :id,
      title: :title,
      ability: :ability, 
      icon: :icon,
      exp: :exp,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      is_task: :is_task, 
      prerequisiteIDs: :prerequisiteIDs, 
      goal: :goal, 
      progress: :progress
    })
  end
end
