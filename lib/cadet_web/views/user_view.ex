defmodule CadetWeb.UserView do
  use CadetWeb, :view

  alias Cadet.Courses

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
      role: cr.role,
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
          courseRegId: latest.id,
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
          gameStates: latest.game_states,
          agreedToResearch: latest.agreed_to_research
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
          enableOverallLeaderboard: :enable_overall_leaderboard,
          enableContestLeaderboard: :enable_contest_leaderboard,
          topLeaderboardDisplay: :top_leaderboard_display,
          topContestLeaderboardDisplay: :top_contest_leaderboard_display,
          enableSourcecast: :enable_sourcecast,
          enableStories: :enable_stories,
          sourceChapter: :source_chapter,
          sourceVariant: :source_variant,
          moduleHelpText: :module_help_text,
          assetsPrefix: &Courses.assets_prefix/1
        })
    end
  end

  defp render_assessment_configs(latest) do
    case latest do
      nil ->
        nil

      latest ->
        Enum.map(latest.course.assessment_config, fn config ->
          transform_map_for_view(config, %{
            assessmentConfigId: :id,
            type: :type,
            displayInDashboard: :show_grading_summary,
            isMinigame: :is_minigame,
            isManuallyGraded: :is_manually_graded,
            hasVotingFeatures: :has_voting_features,
            hasTokenCounter: :has_token_counter,
            earlySubmissionXp: :early_submission_xp,
            hoursBeforeEarlyXpDecay: :hours_before_early_xp_decay,
            isGradingAutoPublished: :is_grading_auto_published
          })
        end)
    end
  end
end
