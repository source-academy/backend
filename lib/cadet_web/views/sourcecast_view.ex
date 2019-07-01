defmodule CadetWeb.SourcecastView do
  use CadetWeb, :view

  import CadetWeb.AssessmentsHelpers

  def render("index.json", %{sourcecasts: sourcecasts}) do
    render_many(sourcecasts, CadetWeb.SourcecastView, "show.json", as: :sourcecast)
  end

  def render("show.json", %{sourcecast: sourcecast}) do
    transform_map_for_view(sourcecast, %{
      name: :name,
      inserted_at: :inserted_at,
      updated_at: :updated_at,
      audio: :audio,
      deltas: :deltas,
      id: :id,
      uploader_id: :uploader_id,
      url: &Cadet.Course.Upload.url({&1.audio, &1})
    })
  end
end
