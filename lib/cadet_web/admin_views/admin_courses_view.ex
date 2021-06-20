defmodule CadetWeb.AdminCoursesView do
  use CadetWeb, :view

  def render("assessment_configs.json", %{configs: configs}) do
    render_many(configs, CadetWeb.AdminCoursesView, "config.json", as: :config)
  end

  def render("config.json", %{config: config}) do
    transform_map_for_view(config, %{
      order: &(&1.assessment_type.order),
      type: &(&1.assessment_type.type),
      isGraded: &(&1.assessment_type.is_graded),
      decayRatePointsPerHour: :decay_rate_points_per_hour,
      earlySubmissionXp: :early_submission_xp,
      hoursBeforeEarlyXpDecay: :hours_before_early_xp_decay
    })
  end
end
