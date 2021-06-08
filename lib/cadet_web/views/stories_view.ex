defmodule CadetWeb.StoriesView do
  use CadetWeb, :view

  def render("index.json", %{stories: stories}) do
    render_many(stories, CadetWeb.StoriesView, "show.json", as: :story)
  end

  def render("show.json", %{story: story}) do
    transform_map_for_view(story, %{
      id: :id,
      title: :title,
      filenames: :filenames,
      imageUrl: :image_url,
      isPublished: :is_published,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      courseId: :course_id
    })
  end
end
