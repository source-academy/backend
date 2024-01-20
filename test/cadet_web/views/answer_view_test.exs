defmodule CadetWeb.AnswerViewTest do
  use CadetWeb.ConnCase, async: true

  alias CadetWeb.AnswerView

  @last_modified ~U[2022-01-01T00:00:00Z]

  describe "render/2" do
    test "renders last modified timestamp as JSON" do
      json = AnswerView.render("lastModified.json", %{lastModified: @last_modified})

      assert json[:lastModified] == @last_modified
    end
  end
end
