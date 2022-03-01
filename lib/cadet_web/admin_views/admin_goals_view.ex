defmodule CadetWeb.AdminGoalsView do
  use CadetWeb, :view
  use Timex

  def render("index.json", %{goals: goals}) do
    render_many(goals, CadetWeb.AdminGoalsView, "goal.json", as: :goal)
  end

  def render("index_goals_with_progress.json", %{goals: goals}) do
    render_many(goals, CadetWeb.AdminGoalsView, "goal_with_progress.json", as: :goal)
  end

  def render("goal.json", %{goal: goal}) do
    transform_map_for_view(goal, %{
      uuid: :uuid,
      text: :text,
      targetCount: :target_count,
      type: :type,
      meta: :meta
    })
  end

  def render("goal_with_progress.json", %{goal: goal}) do
    transform_map_for_view(goal, %{
      uuid: :uuid,
      text: :text,
      count: fn
        %{progress: [%{count: count}]} -> count
        _ -> 0
      end,
      completed: fn
        %{progress: [%{completed: completed}]} -> completed
        _ -> false
      end,
      targetCount: :target_count,
      type: :type,
      meta: :meta,
      achievementUuids:
        &Enum.map(&1.achievements, fn achievement -> achievement.achievement_uuid end)
    })
  end
end
