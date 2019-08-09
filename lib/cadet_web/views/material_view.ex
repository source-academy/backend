defmodule CadetWeb.MaterialView do
  use CadetWeb, :view

  def render("index.json", %{materials: materials}) do
    render_many(materials, CadetWeb.MaterialView, "show.json", as: :material)
  end

  def render("show.json", %{material: material}) do
    transform_map_for_view(material, %{
      title: :title,
      description: :description,
      inserted_at: :inserted_at,
      updated_at: :updated_at,
      id: :id,
      uploader: &transform_map_for_view(&1.uploader, [:name, :id]),
      url: &url_builder(&1)
    })
  end

  defp url_builder(material) do
    if Map.has_key?(material, :file) do
      Cadet.Course.Upload.url({material.file, material})
    else
      nil
    end
  end
end
