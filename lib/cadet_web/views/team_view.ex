defmodule CadetWeb.TeamView do
  @moduledoc """
  View module for rendering team-related data as JSON.
  """

  use CadetWeb, :view

  @doc """
  Renders the JSON representation of team formation overview.

  ## Parameters

    * `teamFormationOverview` - A map containing team formation overview data.

  """
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
