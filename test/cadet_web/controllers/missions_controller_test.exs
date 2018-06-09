defmodule CadetWeb.MissionsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.MissionsController

  test "swagger" do
    MissionsController.swagger_definitions()
    MissionsController.swagger_path_index(nil)
  end
end
