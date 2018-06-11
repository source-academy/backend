defmodule CadetWeb.MissionsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.MissionsController

  test "swagger" do
    MissionsController.swagger_definitions()
    MissionsController.swagger_path_index(nil)
    MissionsController.swagger_path_open(nil)
    MissionsController.swagger_path_questions(nil)
  end
end
