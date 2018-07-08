defmodule CadetWeb.AnswerControllerTest do
  use CadetWeb.ConnCase
  use Cadet.DataCase

  alias CadetWeb.AnswerController

  test "swagger" do
    AnswerController.swagger_definitions()
    AnswerController.swagger_path_submit(nil)
  end

  setup do
    assessment = insert(:assessment)
    mcq_question = insert(:question, %{assessment: assessment, type: :multiple_choice})
    programming_question = insert(:question, %{assessment: assessment, type: :programming})


  end

  describe



end
