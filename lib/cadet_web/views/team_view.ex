defmodule CadetWeb.TeamView do
  use CadetWeb, :view

  def render("index.json", %{teamFormationOverview: teamFormationOverview}) do
    %{
      teamId: teamFormationOverview.teamId,
      assessmentId: teamFormationOverview.assessmentId,
      assessmentName: teamFormationOverview.assessmentName,
      assessmentType: teamFormationOverview.assessmentType,
      studentIds: teamFormationOverview.studentIds,
      studentNames: teamFormationOverview.studentNames
    }
  end
end
