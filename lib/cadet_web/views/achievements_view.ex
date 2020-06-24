defmodule CadetWeb.AchievementsView do
  
  use CadetWeb, :view
  use Timex

  import CadetWeb.AssessmentsHelpers

  def render("index.json", %{achievements: achievements}) do
    render_many(achievements, CadetWeb.AchievementsView, "overview.json", as: :achievement)
  end

  def render("overview.json", %{achievement: achievement}) do
    transform_map_for_view(achievement, %{
      inferencer_id: :inferencer_id, 
      id: :id,
      title: :title,
      ability: :ability, 
      icon: :icon,
      exp: :exp,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      isTask: :is_task, 
      prerequisiteIDs: :prerequisite_ids, 
      goal: :goal, 
      progress: :progress, 

      modalImageUrl: :modal_image_url, 
      description: :description, 
      goalText: :goal_text, 
      completionText: :completion_text
    })
  end
end
