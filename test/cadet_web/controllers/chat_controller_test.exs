defmodule CadetWeb.ChatControllerTest do
  alias CadetWeb.ChatController
  use CadetWeb.ConnCase
  @moduletag :serial

  @tag authenticate: :student
  setup context do
    if context[:requires_setup] do
      response =
        post(context.conn, "/v2/chats", %{
          "section" => "1.2",
          "initialContext" => "Recursion is a fundamental concept in computer science."
        })

      decoded_body = Jason.decode!(response.resp_body)
      conversation_id = decoded_body["conversationId"]
      {:ok, conversation_id: conversation_id}
    else
      {:ok, conversation_id: nil}
    end
  end

  test "swagger" do
    ChatController.swagger_path_chat("json")
  end

  describe "POST /chat" do
    test "unauthenticated request", %{conn: conn} do
      conn =
        post(conn, "/v2/chats", %{"json" => [%{"role" => "assistant", "content" => "Hello"}]})

      assert response(conn, 401) == "Unauthorised"
    end

    @tag authenticate: :student
    test "invalid course section", %{conn: conn} do
      conn =
        post(conn, "/v2/chats", %{
          "section" => "invalid course section",
          "initialContext" => "Recursion is a fundamental concept in computer science."
        })

      assert response(conn, :bad_request) == "Invalid course section"
    end

    @tag authenticate: :student
    test "missing section info", %{conn: conn} do
      conn =
        post(conn, "/v2/chats", %{
          "section" => nil,
          "initialContext" => "Recursion is a fundamental concept in computer science."
        })

      assert response(conn, :bad_request) == "Missing course section"
    end

    @tag authenticate: :student
    @tag requires_setup: true
    test "valid user message conversation", %{conn: conn, conversation_id: conversation_id} do
      assert conversation_id != nil

      conn =
        post(conn, "/v2/chats/#{conversation_id}/message", %{
          "conversation_id" => conversation_id,
          "message" => "How to implement recursion in JavaScript?"
        })

      assert response(conn, 200)
    end

    @tag authenticate: :student
    test "invalid conversation id", %{conn: conn} do
      conversation_id = "-1"

      conn =
        post(conn, "/v2/chats/#{conversation_id}/message", %{
          "conversation_id" => conversation_id,
          "message" => "How to implement recursion in JavaScript?"
        })

      assert response(conn, 500) == "Conversation not found"
    end
  end
end
