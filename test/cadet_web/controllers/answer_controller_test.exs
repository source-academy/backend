defmodule CadetWeb.AnswerControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.AnswerController

  test "swagger" do
    AnswerController.swagger_definitions()
    AnswerController.swagger_path_submit(nil)
  end
end
