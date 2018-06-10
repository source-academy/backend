defmodule CadetWeb.Answer.MCQAnswerControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Answer.MCQAnswerController

  test "swagger" do
    MCQAnswerController.swagger_definitions()
    MCQAnswerController.swagger_path_submit(nil)
    MCQAnswerController.swagger_path_show(nil)
  end
end
