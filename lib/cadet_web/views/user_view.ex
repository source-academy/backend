defmodule CadetWeb.UserView do
  use CadetWeb, :view

  # def render("index.json", %{
  #       user: user,
  #       cr: cr,
  #       grade: grade,
  #       max_grade: max_grade,
  #       xp: xp,
  #       story: story
  #     }) do
  #   %{
  #     userId: user.id,
  #     name: user.name,
  #     role: cr.role,
  #     group:
  #       case cr.group do
  #         nil -> nil
  #         _ -> cr.group.name
  #       end,
  #     grade: grade,
  #     xp: xp,
  #     maxGrade: max_grade,
  #     story:
  #       transform_map_for_view(story, %{
  #         story: :story,
  #         playStory: :play_story?
  #       }),
  #     gameStates: cr.game_states
  #   }
  # end

  def render("index.json", %{
        user: user,
        courses: courses,
        latest: latest,
        grade: grade,
        max_grade: max_grade,
        xp: xp,
        story: story
      }) do
    %{
      user: %{
        userId: user.id,
        name: user.name,
        courses: render_many(courses, CadetWeb.UserView, "course.json", as: :cr)
      },
      courseRegistration:
        render_latest(%{
          latest: latest,
          grade: grade,
          max_grade: max_grade,
          xp: xp,
          story: story
        }),
      courseConfiguration: render_config(latest)
    }
  end

  def render("course.json", %{
        latest: latest,
        grade: grade,
        max_grade: max_grade,
        xp: xp,
        story: story
      }) do
    %{
      courseRegistration:
        render_latest(%{
          latest: latest,
          grade: grade,
          max_grade: max_grade,
          xp: xp,
          story: story
        }),
      courseConfiguration: render_config(latest)
    }
  end

  def render("course.json", %{cr: cr}) do
    %{
      course_id: cr.course_id,
      name: cr.course.name,
      moduleCode: cr.course.module_code,
      viewable: cr.course.viewable
    }
  end

  defp render_latest(%{
         latest: latest,
         grade: grade,
         max_grade: max_grade,
         xp: xp,
         story: story
       }) do
    case latest do
      nil ->
        nil

      _ ->
        %{
          courseId: latest.course_id,
          role: latest.role,
          group:
            case latest.group do
              nil -> nil
              _ -> latest.group.name
            end,
          grade: grade,
          xp: xp,
          maxGrade: max_grade,
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
          moduleName: :name,
          moduleCode: :module_code,
          viewable: :viewable,
          enableGame: :enable_game,
          enableAchievements: :enable_achievements,
          enableSourcecast: :enable_sourcecast,
          sourceChapter: :source_chapter,
          sourceVariant: :source_variant,
          moduleHelpText: :module_help_text,
          assessmentTypes: :assessment_types
        })
    end
  end
end
