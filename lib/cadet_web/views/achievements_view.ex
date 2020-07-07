defmodule CadetWeb.AchievementsView do
  
  use CadetWeb, :view
  use Timex

  alias Cadet.Achievements.AchievementGoal
  
  def render("index.json", %{achievements: achievements}) do
    render_many(achievements, CadetWeb.AchievementsView, "overview.json", as: :achievement)
  end

  def render("overview.json", %{achievement: achievement}) do
    transform_map_for_view(achievement, %{
      inferencer_id: :inferencer_id, 
      id: :id,
      title: :title,
      ability: :ability, 
      exp: :exp,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      isTask: :is_task, 
      prerequisiteIds: :prerequisite_ids, 
      position: :position, 
      backgroundImageUrl: :background_image_url, 

      modalImageUrl: :modal_image_url, 
      description: :description, 
      goalText: :goal_text, 
      completionText: :completion_text, 

      goals: &Enum.map(&1.goals, fn goal ->
        transform_map_for_view(goal, %{
          goalId: goal.goal_id, 
          goalText: goal.goal_text, 
          goalProgress: goal.goal_progress, 
          goalTarget: goal.goal_target
        })
      end)
    })
  end
end
