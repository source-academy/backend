defmodule CadetWeb.AdminControllerTest do
  use CadetWeb.ConnCase

  describe "Unauthenticated User" do
    test "GET /admin"
  end

  @tag authenticate: :student
  describe "Authenticated Student" do
    test "GET /admin"
  end

  @tag authenticate: :admin
  describe "Authenticated Admin" do
    test "GET /admin"
  end
end
