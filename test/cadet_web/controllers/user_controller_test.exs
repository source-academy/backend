defmodule CadetWeb.UserControllerTest do
  use CadetWeb.ConnCase

  alias CadetWeb.UserController

  test "swagger" do
    assert is_map(UserController.swagger_definitions())
    assert is_map(UserController.swagger_path_index(nil))
  end
end
