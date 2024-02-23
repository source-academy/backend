defmodule CadetWeb.ChatControllerTest do
  alias CadetWeb.ChatController
  use CadetWeb.ConnCase

  test "swagger" do
    ChatController.swagger_path_chat("json")
  end

  describe "POST /chat" do
    test "unauthenticated request", %{conn: conn} do
      conn = post(conn, "/v2/chat", %{"json" => [%{"role" => "assistant", "content" => "Hello"}]})

      assert response(conn, 401) == "Unauthorised"
    end

    @tag authenticate: :student
    test "parameter not in json", %{conn: conn} do
      conn =
        post(conn, "/v2/chat", %{
          "_json" => [
            %{"role" => "assistant", "content" => "Hello"},
            %{"role" => "user", "content" => "Hi"}
          ]
        })

      assert response(conn, 400) == "Request must be in JSON format"
    end

    @tag authenticate: :student
    test "parameter is empty", %{conn: conn} do
      conn = post(conn, "/v2/chat", %{"json" => []})

      assert response(conn, 400) ==
               "Request must be a non empty list of message of format: {role:string, content:string}"
    end

    @tag authenticate: :student
    test "invalid parameter format", %{conn: conn} do
      conn = post(conn, "/v2/chat", %{"json" => [%{rol: "role", contents: "content"}]})

      assert response(conn, 400) ==
               "Request must be a non empty list of message of format: {role:string, content:string}"
    end

    @tag authenticate: :student
    test "valid chat but without api key", %{conn: conn} do
      conn =
        post(conn, "/v2/chat", %{
          "json" => [
            %{"role" => "assistant", "content" => "Hello"},
            %{"role" => "user", "content" => "Hi"}
          ]
        })

      assert response(conn, 500)
    end
  end
end
