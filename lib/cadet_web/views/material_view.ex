defmodule CadetWeb.MaterialView do
  use CadetWeb, :view

  def render("index.json", %{materials: materials, directory_tree: directory_tree}) do
    %{
      index: render_many(materials, CadetWeb.MaterialView, "show.json", as: :material),
      directory_tree: directory_tree |> Enum.map(&%{id: &1.id, title: &1.title})
    }
  end

  def render("show.json", %{material: material}) do
    transform_map_for_view(material, %{
      title: :title,
      description: :description,
      inserted_at: &format_datetime(&1.inserted_at),
      updated_at: &format_datetime(&1.updated_at),
      id: :id,
      uploader: &transform_map_for_view(&1.uploader, [:name, :id]),
      url: &url_builder(&1)
    })
  end

  defp url_builder(material) do
    if Map.has_key?(material, :file) do
      Cadet.Course.MaterialUpload.url({material.file, material})
    else
      nil
    end
  end
end
