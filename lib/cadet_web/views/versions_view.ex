defmodule CadetWeb.VersionsView do
  use CadetWeb, :view

  def render("index.json", %{versions: versions}) do
    render_many(versions, CadetWeb.VersionsView, "show.json", as: :version)
  end

  def render("show.json", %{version: version}) do
    transform_map_for_view(version, %{
      id: :id,
      name: :name,
      restored: :restored,
      restored_from: :restored_from,
      answer_id: :answer_id,
      inserted_at: :inserted_at,
      updated_at: :updated_at,
      content: :content
    })
  end
end
