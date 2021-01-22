defmodule CadetWeb.AdminGoalsView do
  use CadetWeb, :view
  use Timex

  def render("index.json", %{goals: goals}) do
    render_many(goals, CadetWeb.AdminGoalsView, "goal.json", as: :goal)
  end

  def render("goal.json", %{goal: goal}) do
    transform_map_for_view(goal, %{
      uuid: :uuid,
      text: :text,
      maxExp: :max_xp,
      type: :type,
      meta: :meta
    })
  end
end
