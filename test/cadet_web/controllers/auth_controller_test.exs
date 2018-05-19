defmodule CadetWeb.AuthControllerTest do
  use CadetWeb.ConnCase

  import Cadet.Factory

  alias CadetWeb.AuthController

  test "swagger" do
    AuthController.swagger_definitions()
    AuthController.swagger_path_create(nil)
    AuthController.swagger_path_refresh(nil)
    AuthController.swagger_path_logout(nil)
  end
end
