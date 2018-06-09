defmodule CadetWeb.ProgrammingSubmissionControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.ProgrammingSubmissionController

  test "swagger" do
    ProgrammingSubmissionController.swagger_definitions()
    ProgrammingSubmissionController.swagger_path_create(nil)
    ProgrammingSubmissionController.swagger_path_update(nil)
  end
end
