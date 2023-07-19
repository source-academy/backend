defmodule CadetWeb.AdminTeamsView do
  use CadetWeb, :view

  def render("index.json", %{teamFormationOverviews: teamFormationOverviews}) do
    render_many(teamFormationOverviews, CadetWeb.AdminTeamsView, "team_formation_overview.json", as: :team_formation_overview)
  end

  def render("team_formation_overview.json", %{team_formation_overview: team_formation_overview}) do
    %{
      teamId: team_formation_overview.teamId,
      assessmentId: team_formation_overview.assessmentId,
      assessmentName: team_formation_overview.assessmentName,
      assessmentType: team_formation_overview.assessmentType,
      studentIds: team_formation_overview.studentIds,
      studentNames: team_formation_overview.studentNames
    }
  end
end
