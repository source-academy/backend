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
      latestViewedCourse: render_latest(%{
        latest: latest,
        grade: grade,
        max_grade: max_grade,
        xp: xp,
        story: story
      })
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
      nil -> nil

      _ ->%{
        course: transform_map_for_view(latest.course, [
          :name,
          :module_code,
          :viewable,
          :enable_game,
          :enable_achievements,
          :enable_sourcecast,
          :source_chapter,
          :source_variant,
          :module_help_text,
          :assessment_types
        ]),
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


end
