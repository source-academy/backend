defmodule CadetWeb.AssessmentsControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AssessmentsController

  test "swagger" do
    AssessmentsController.swagger_definitions()
    AssessmentsController.swagger_path_index(nil)
    AssessmentsController.swagger_path_show(nil)
  end
end
