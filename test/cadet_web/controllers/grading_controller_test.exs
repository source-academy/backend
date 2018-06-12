defmodule CadetWeb.GradingControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.GradingController

  test "swagger" do
    GradingController.swagger_definitions()
    GradingController.swagger_path_index(nil)
    GradingController.swagger_path_show(nil)
  end
end
