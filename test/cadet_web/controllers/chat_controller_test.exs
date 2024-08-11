defmodule CadetWeb.ChatControllerTest do
  alias CadetWeb.ChatController
  use CadetWeb.ConnCase
  @moduletag :serial

  @tag authenticate: :student
  setup context do
    if context[:requires_setup] do
      conversation = insert(:conversation)
      {:ok, conversation_id: conversation.id}
    else
      {:ok, conversation_id: nil}
    end
  end

  test "swagger" do
    ChatController.swagger_path_chat("json")
  end

  describe "POST /chats" do
    test "unauthenticated request", %{conn: conn} do
      conn =
        post(conn, "/v2/chats", %{"json" => [%{"role" => "assistant", "content" => "Hello"}]})

      assert response(conn, :unauthorized) == "Unauthorised"
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
  end

  describe "POST /chats/:conversationId/message" do
    @tag authenticate: :student
    @tag requires_setup: true
    test "valid user message conversation. However this fails because github ci does have a valid api key",
         %{conn: conn, conversation_id: conversation_id} do
      assert conversation_id != nil

      conn =
        post(conn, "/v2/chats/#{conversation_id}/message", %{
          "conversation_id" => conversation_id,
          "message" => "How to implement recursion in JavaScript?"
        })

      assert response(conn, 500) ==
               "You didn't provide an API key. You need to provide your API key in an Authorization header using Bearer auth (i.e. Authorization: Bearer YOUR_KEY), or as the password field (with blank username) if you're accessing the API from your browser and are prompted for a username and password. You can obtain an API key from https://platform.openai.com/account/api-keys."
    end

    @tag authenticate: :student
    test "invalid conversation id", %{conn: conn} do
      conversation_id = "-1"

      conn =
        post(conn, "/v2/chats/#{conversation_id}/message", %{
          "conversation_id" => conversation_id,
          "message" => "How to implement recursion in JavaScript?"
        })

      assert response(conn, :not_found) == "Conversation not found"
    end
  end
end
