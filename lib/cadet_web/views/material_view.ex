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
      file: :file,
      id: :id,
      uploader: &transform_map_for_view(&1.uploader, [:name, :id]),
      url: &Cadet.Course.Upload.url({&1.file, &1})
    })
  end
end
