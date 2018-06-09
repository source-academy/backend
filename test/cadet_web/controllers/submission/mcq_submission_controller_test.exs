defmodule CadetWeb.Submission.MCQSubmissionControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Submission.MCQSubmissionController

  test "swagger" do
    MCQSubmissionController.swagger_definitions()
    MCQSubmissionController.swagger_path_submit(nil)
  end
end
