defmodule CadetWeb.AdminTeamsView do
  @moduledoc """
  View module for rendering admin teams data in JSON format.
  """

  use CadetWeb, :view

  @doc """
  Renders a list of team formation overviews in JSON format.

  ## Parameters

  * `teamFormationOverviews` - A list of team formation overviews to be rendered.

  """
  def render("index.json", %{team_formation_overviews: team_formation_overviews}) do
    render_many(team_formation_overviews, CadetWeb.AdminTeamsView, "team_formation_overview.json",
      as: :team_formation_overview
    )
  end

  @doc """
  Renders a single team formation overview in JSON format.

  ## Parameters

  * `team_formation_overview` - The team formation overview to be rendered.

  """
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
