defmodule CadetWeb.CoursesView do
  use CadetWeb, :view

  def render("config.json", %{config: config}) do
    %{
      config:
        transform_map_for_view(config, %{
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
          enableExamMode: :enable_exam_mode,
          isOfficialCourse: :is_official_course,
          sourceChapter: :source_chapter,
          sourceVariant: :source_variant,
          moduleHelpText: :module_help_text,
          assessmentTypes: :assessment_configs,
          assetsPrefix: :assets_prefix
        })
    }
  end

  def render("config_admin.json", %{config: config}) do
    %{
      config:
        transform_map_for_view(config, %{
          courseName: :course_name,
          courseShortName: :course_short_name,
          viewable: :viewable,
          enableGame: :enable_game,
          enableAchievements: :enable_achievements,
          enableSourcecast: :enable_sourcecast,
          enableStories: :enable_stories,
          enableExamMode: :enable_exam_mode,
          isOfficialCourse: :is_official_course,
          resumeCode: :resume_code,
          sourceChapter: :source_chapter,
          sourceVariant: :source_variant,
          moduleHelpText: :module_help_text,
          assessmentTypes: :assessment_configs,
          assetsPrefix: :assets_prefix
        })
    }
  end
end
