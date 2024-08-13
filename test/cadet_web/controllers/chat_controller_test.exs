defmodule CadetWeb.ChatControllerTest do
  alias CadetWeb.ChatController
  use CadetWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @moduletag :serial

  setup_all do
    # This essentially does :application.ensure_all_started(:hackney)
    HTTPoison.start()
  end

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
    test "Conversation belongs to another user", %{conn: conn, conversation_id: conversation_id} do
      assert conversation_id != nil

      use_cassette "chatbot/chat_conversation#1", custom: true do
        conn =
          post(conn, "/v2/chats/#{conversation_id}/message", %{
            "message" => "How to implement recursion in JavaScript?"
          })

        assert response(conn, :not_found) == "Conversation not found"
      end
    end

    @tag authenticate: :student
    test "Conversation belongs to own user", %{conn: conn} do
      use_cassette "chatbot/chat_conversation#1", custom: true do
        conversation = insert(:conversation, user: conn.assigns.current_user)

        conn =
          post(conn, "/v2/chats/#{conversation.id}/message", %{
            "message" => "How to implement recursion in JavaScript?"
          })

        assert json_response(conn, 200) == %{
                 "conversationId" => Integer.to_string(conversation.id),
                 "response" => "Some hardcoded test response."
               }
      end
    end

    @tag authenticate: :student
    @tag requires_setup: true
    test "The content length is too long",
         %{conn: conn, conversation_id: conversation_id} do
      assert conversation_id != nil
      max_message_length = ChatController.max_content_length()
      message_exceed_length = String.duplicate("a", max_message_length + 1)

      conn =
        post(conn, "/v2/chats/#{conversation_id}/message", %{
          "conversation_id" => conversation_id,
          "message" => "#{message_exceed_length}"
        })

      assert response(conn, :unprocessable_entity) ==
               "Message exceeds the maximum allowed length of #{max_message_length}"
    end

    @tag authenticate: :student
    @tag requires_setup: true
    test "The content length less than the maximum allowed length but conversation belongs to another user",
         %{conn: conn, conversation_id: conversation_id} do
      assert conversation_id != nil
      max_message_length = ChatController.max_content_length()
      message_exceed_length = String.duplicate("a", max_message_length)

      conn =
        post(conn, "/v2/chats/#{conversation_id}/message", %{
          "conversation_id" => conversation_id,
          "message" => "#{message_exceed_length}"
        })

      assert response(conn, :not_found) == "Conversation not found"
    end

    @tag authenticate: :student
    test "invalid conversation id", %{conn: conn} do
      conversation_id = "-1"

      conn =
        post(conn, "/v2/chats/#{conversation_id}/message", %{
          "message" => "How to implement recursion in JavaScript?"
        })

      assert response(conn, :not_found) == "Conversation not found"
    end
  end
end
