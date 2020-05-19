defmodule CadetWeb.ChaptersView do
  use CadetWeb, :view

  def render("show.json", %{chapter: chapter}) do
    %{
      chapter:
        transform_map_for_view(chapter, %{
          chapterno: :chapterno,
          variant: :variant
        })
    }
  end
end
