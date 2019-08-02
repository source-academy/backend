defmodule CadetWeb.SourcecastView do
  use CadetWeb, :view

  def render("index.json", %{sourcecasts: sourcecasts}) do
    render_many(sourcecasts, CadetWeb.SourcecastView, "show.json", as: :sourcecast)
  end

  def render("show.json", %{sourcecast: sourcecast}) do
    transform_map_for_view(sourcecast, %{
      id: :id,
      title: :title,
      description: :description,
      inserted_at: :inserted_at,
      updated_at: :updated_at,
      audio: :audio,
      playbackData: :playbackData,
      uploader: &transform_map_for_view(&1.uploader, [:name, :id]),
      url: &Cadet.Course.Upload.url({&1.audio, &1})
    })
  end
end
