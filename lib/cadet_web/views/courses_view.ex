defmodule CadetWeb.CoursesView do
  use CadetWeb, :view

  def render("sublanguage.json", %{sublanguage: sublanguage}) do
    %{
      sublanguage: transform_map_for_view(sublanguage, [:source_chapter, :source_variant])
    }
  end
end
