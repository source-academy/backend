defmodule CadetWeb.AdminCoursesView do
  use CadetWeb, :view

  def render("assessment_configs.json", %{configs: configs}) do
    render_many(configs, CadetWeb.AdminCoursesView, "config.json", as: :config)
  end

  def render("config.json", %{config: config}) do
    transform_map_for_view(config, %{
      assessmentConfigId: :id,
      type: :type,
      displayInDashboard: :show_grading_summary,
      isMinigame: :is_minigame,
      isManuallyGraded: :is_manually_graded,
      earlySubmissionXp: :early_submission_xp,
      hasVotingFeatures: :has_voting_features,
      hasTokenCounter: :has_token_counter,
      hoursBeforeEarlyXpDecay: :hours_before_early_xp_decay,
      isGradingAutoPublished: :is_grading_auto_published
    })
  end
end
