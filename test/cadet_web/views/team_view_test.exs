defmodule CadetWeb.TeamViewTest do
  use CadetWeb.ConnCase, async: true

  alias CadetWeb.TeamView

  @teamFormationOverview %{
    teamId: 1,
    assessmentId: 2,
    assessmentName: "Test Assessment",
    assessmentType: "Test Type",
    studentIds: [1, 2, 3],
    studentNames: ["Alice", "Bob", "Charlie"]
  }

  describe "render/2" do
    test "renders team formation overview as JSON" do
      json = TeamView.render("index.json", %{teamFormationOverview: @teamFormationOverview})

      assert json[:teamId] == @teamFormationOverview.teamId
      assert json[:assessmentId] == @teamFormationOverview.assessmentId
      assert json[:assessmentName] == @teamFormationOverview.assessmentName
      assert json[:assessmentType] == @teamFormationOverview.assessmentType
      assert json[:studentIds] == @teamFormationOverview.studentIds
      assert json[:studentNames] == @teamFormationOverview.studentNames
    end
  end
end