defmodule CadetWeb.RouterTest do
  use ExUnit.Case, async: true

  alias CadetWeb.Router

  test "Swagger" do
    Router.swagger_info
  end
end
