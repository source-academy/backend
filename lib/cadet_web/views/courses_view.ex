defmodule CadetWeb.CoursesView do
  use CadetWeb, :view

  def render("config.json", %{config: config}) do
    %{
      config:
        transform_map_for_view(config, [
          :name,
          :module_code,
          :viewable,
          :enable_game,
          :enable_achievements,
          :enable_sourcecast,
          :source_chapter,
          :source_variant,
          :module_help_text
        ])
    }
  end
end
