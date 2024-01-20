defmodule CadetWeb.TeamViewTest do
  use CadetWeb.ConnCase, async: true

  alias CadetWeb.TeamView

  @team_formation_overview %{
    teamId: 1,
    assessmentId: 2,
    assessmentName: "Test Assessment",
    assessmentType: "Test Type",
    studentIds: [1, 2, 3],
    studentNames: ["Alice", "Bob", "Charlie"]
  }

  describe "render/2" do
    test "renders team formation overview as JSON" do
      json = TeamView.render("index.json", %{teamFormationOverview: @team_formation_overview})

      assert json[:teamId] == @team_formation_overview.teamId
      assert json[:assessmentId] == @team_formation_overview.assessmentId
      assert json[:assessmentName] == @team_formation_overview.assessmentName
      assert json[:assessmentType] == @team_formation_overview.assessmentType
      assert json[:studentIds] == @team_formation_overview.studentIds
      assert json[:studentNames] == @team_formation_overview.studentNames
    end
  end
end
