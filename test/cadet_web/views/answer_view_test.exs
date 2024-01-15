defmodule CadetWeb.AnswerViewTest do
  use CadetWeb.ConnCase, async: true

  alias CadetWeb.AnswerView

  @lastModified ~U[2022-01-01T00:00:00Z]

  describe "render/2" do
    test "renders last modified timestamp as JSON" do
      json = AnswerView.render("lastModified.json", %{lastModified: @lastModified})

      assert json[:lastModified] == @lastModified
    end
  end
end