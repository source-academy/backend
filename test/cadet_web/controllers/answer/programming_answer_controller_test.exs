defmodule CadetWeb.Answer.ProgrammingAnswerControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.Answer.ProgrammingAnswerController

  test "swagger" do
    ProgrammingAnswerController.swagger_definitions()
    ProgrammingAnswerController.swagger_path_submit(nil)
    ProgrammingAnswerController.swagger_path_show(nil)
  end
end
