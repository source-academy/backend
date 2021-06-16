defmodule CadetWeb.CoursesView do
  use CadetWeb, :view

  def render("config.json", %{config: config}) do
    %{
      config:
        transform_map_for_view(config, %{
          courseName: :name,
          courseShortName: :module_code,
          viewable: :viewable,
          enableGame: :enable_game,
          enableAchievements: :enable_achievements,
          enableSourcecast: :enable_sourcecast,
          sourceChapter: :source_chapter,
          sourceVariant: :source_variant,
          moduleHelpText: :module_help_text,
          assessmentTypes: :assessment_types
        })
    }
  end
end
