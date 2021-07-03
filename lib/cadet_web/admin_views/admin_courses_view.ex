defmodule CadetWeb.AdminCoursesView do
  use CadetWeb, :view

  def render("assessment_configs.json", %{configs: configs}) do
    render_many(configs, CadetWeb.AdminCoursesView, "config.json", as: :config)
  end

  def render("config.json", %{config: config}) do
    transform_map_for_view(config, %{
      assessmentConfigId: :id,
      type: :type,
      skippable: :skippable,
      isGraded: :is_graded,
      isAutograded: :is_autograded,
      earlySubmissionXp: :early_submission_xp,
      hoursBeforeEarlyXpDecay: :hours_before_early_xp_decay
    })
  end
end
