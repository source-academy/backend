defmodule CadetWeb.Submission.ProgrammingSubmissionControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Submission.ProgrammingSubmissionController

  test "swagger" do
    ProgrammingSubmissionController.swagger_definitions()
    ProgrammingSubmissionController.swagger_path_submit(nil)
  end
end
