defmodule CadetWeb.IncentivesView do
  use CadetWeb, :view
  use Timex

  def render("index_achievements.json", %{achievements: achievements}) do
    render_many(achievements, CadetWeb.IncentivesView, "achievement.json", as: :achievement)
  end

  def render("achievement.json", %{achievement: achievement}) do
    transform_map_for_view(achievement, %{
      uuid: :uuid,
      title: :title,
      ability: :ability,
      release: &format_datetime(&1.open_at),
      deadline: &format_datetime(&1.close_at),
      isTask: :is_task,
      prerequisiteUuids:
        &Enum.map(&1.prerequisites, fn prerequisite -> prerequisite.prerequisite_uuid end),
      cardBackground: :card_tile_url,
      position: :position,
      view:
        &%{
          coverImage: &1.canvas_url,
          description: &1.description,
          completionText: &1.completion_text
        },
      goalUuids: &Enum.map(&1.goals, fn goal -> goal.goal_uuid end)
    })
  end

  def render("index_goals_with_progress.json", %{goals: goals}) do
    render_many(goals, CadetWeb.IncentivesView, "goal_with_progress.json", as: :goal)
  end

  def render("goal_with_progress.json", %{goal: goal}) do
    transform_map_for_view(goal, %{
      uuid: :uuid,
      text: :text,
      xp: fn
        %{progress: [%{xp: xp}]} -> xp
        _ -> 0
      end,
      completed: fn
        %{progress: [%{completed: completed}]} -> completed
        _ -> false
      end,
      maxXp: :max_xp,
      type: :type,
      meta: :meta
    })
  end
end
