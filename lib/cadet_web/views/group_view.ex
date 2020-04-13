defmodule CadetWeb.GroupView do
  use CadetWeb, :view
  use Timex

  def render("index.json", %{groups: groups}) do
    render_many(groups, CadetWeb.GroupView, "overview.json", as: :group)
  end

  def render("overview.json", %{group: group}) do
    transform_map_for_view(group, %{
      id: :id,
      groupName: :name,
      avengerName: :avenger_name
    })
  end
end
