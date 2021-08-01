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
      uid: :uid,
      inserted_at: &format_datetime(&1.inserted_at),
      updated_at: &format_datetime(&1.updated_at),
      audio: :audio,
      playbackData: :playbackData,
      uploader: &transform_map_for_view(&1.uploader, [:name, :id]),
      url: &Cadet.Courses.SourcecastUpload.url({&1.audio, &1}),
      courseId: :course_id
    })
  end
end
