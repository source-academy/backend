defmodule CadetWeb.UserView do
  use CadetWeb, :view

  def render("index.json", %{
        user: user,
        courses: courses,
        latest: latest,
        max_xp: max_xp,
        xp: xp,
        story: story
      }) do
    %{
      user: %{
        userId: user.id,
        name: user.name,
        courses: render_many(courses, CadetWeb.UserView, "courses.json", as: :cr)
      },
      courseRegistration:
        render_latest(%{
          latest: latest,
          max_xp: max_xp,
          xp: xp,
          story: story
        }),
      courseConfiguration: render_config(latest),
      assessmentConfigurations: render_assessment_configs(latest)
    }
  end

  def render("course.json", %{
        latest: latest,
        max_xp: max_xp,
        xp: xp,
        story: story
      }) do
    %{
      courseRegistration:
        render_latest(%{
          latest: latest,
          max_xp: max_xp,
          xp: xp,
          story: story
        }),
      courseConfiguration: render_config(latest),
      assessmentConfigurations: render_assessment_configs(latest)
    }
  end

  def render("courses.json", %{cr: cr}) do
    %{
      courseId: cr.course_id,
      courseName: cr.course.course_name,
      courseShortName: cr.course.course_short_name,
      viewable: cr.course.viewable
    }
  end

  defp render_latest(%{
         latest: latest,
         max_xp: max_xp,
         xp: xp,
         story: story
       }) do
    case latest do
      nil ->
        nil

      _ ->
        %{
          crId: latest.id,
          courseId: latest.course_id,
          role: latest.role,
          group:
            case latest.group do
              nil -> nil
              _ -> latest.group.name
            end,
          xp: xp,
          maxXp: max_xp,
          story:
            transform_map_for_view(story, %{
              story: :story,
              playStory: :play_story?
            }),
          gameStates: latest.game_states
        }
    end
  end

  defp render_config(latest) do
    case latest do
      nil ->
        nil

      _ ->
        transform_map_for_view(latest.course, %{
          courseName: :course_name,
          courseShortName: :course_short_name,
          viewable: :viewable,
          enableGame: :enable_game,
          enableAchievements: :enable_achievements,
          enableSourcecast: :enable_sourcecast,
          sourceChapter: :source_chapter,
          sourceVariant: :source_variant,
          moduleHelpText: :module_help_text
        })
    end
  end

  defp render_assessment_configs(latest) do
    case latest do
      nil ->
        nil

      latest ->
        Enum.map(latest.course.assessment_config, fn config ->
          transform_map_for_view(config, %{type: :type, skippable: :skippable})
        end)
    end
  end
end
