defmodule Cadet.Chatbot.LlmConversationsTest do
  use Cadet.DataCase

  alias Cadet.Chatbot.LlmConversations

  describe "get_or_create_conversation/1 and /2" do
    test "creates a new conversation when none exists" do
      user = insert(:user)
      assert {:ok, conversation} = LlmConversations.get_or_create_conversation(user.id)
      assert conversation.user_id == user.id
      assert conversation.prepend_context == []
      assert length(conversation.messages) == 1
    end

    test "returns existing conversation" do
      user = insert(:user)
      existing = insert(:conversation, user: user, prepend_context: [])

      assert {:ok, conversation} = LlmConversations.get_or_create_conversation(user.id)
      assert conversation.id == existing.id
    end

    test "stores language metadata on a new conversation" do
      user = insert(:user)

      assert {:ok, conversation} =
               LlmConversations.get_or_create_conversation(user.id, %{language_id: "python2"})

      assert conversation.language_id == "python2"
    end

    test "updates language metadata on an existing conversation" do
      user = insert(:user)
      existing = insert(:conversation, user: user, prepend_context: [], language_id: "python1")

      assert {:ok, conversation} =
               LlmConversations.get_or_create_conversation(user.id, %{language_id: "python3"})

      assert conversation.id == existing.id
      assert conversation.language_id == "python3"
    end
  end

  describe "get_conversation_for_user/1" do
    test "returns error when no conversation exists" do
      user = insert(:user)
      assert {:error, {:not_found, _}} = LlmConversations.get_conversation_for_user(user.id)
    end

    test "returns the conversation for user" do
      user = insert(:user)
      conversation = insert(:conversation, user: user, prepend_context: [])

      assert {:ok, found} = LlmConversations.get_conversation_for_user(user.id)
      assert found.id == conversation.id
    end

    test "ignores RAG conversations" do
      user = insert(:user)
      insert(:conversation, user: user, prepend_context: [%{"chat_type" => "rag"}])

      assert {:error, {:not_found, _}} = LlmConversations.get_conversation_for_user(user.id)
    end

    test "returns non-RAG conversation when user has both types" do
      user = insert(:user)

      rag_conversation =
        insert(:conversation, user: user, prepend_context: [%{"chat_type" => "rag"}])

      non_rag_conversation = insert(:conversation, user: user, prepend_context: [])

      assert {:ok, found} = LlmConversations.get_or_create_conversation(user.id)
      assert found.id == non_rag_conversation.id
      refute found.id == rag_conversation.id
    end
  end

  describe "add_message/3" do
    test "appends a message to the conversation" do
      user = insert(:user)
      conversation = insert(:conversation, user: user, prepend_context: [], messages: [])

      assert {:ok, updated} = LlmConversations.add_message(conversation, "user", "Hello")
      assert length(updated.messages) == 1

      msg = hd(updated.messages)
      assert (msg[:role] || msg["role"]) == "user"
      assert (msg[:content] || msg["content"]) == "Hello"
    end

    test "preserves existing messages" do
      user = insert(:user)

      conversation =
        insert(:conversation,
          user: user,
          prepend_context: [],
          messages: [%{role: "assistant", content: "Hi!"}]
        )

      assert {:ok, updated} = LlmConversations.add_message(conversation, "user", "Hello")
      assert length(updated.messages) == 2
    end
  end

  describe "add_error_message/1" do
    test "adds a system error message" do
      user = insert(:user)
      conversation = insert(:conversation, user: user, prepend_context: [], messages: [])

      assert {:ok, updated} = LlmConversations.add_error_message(conversation)
      assert length(updated.messages) == 1

      msg = hd(updated.messages)
      assert (msg[:role] || msg["role"]) == "system"
      assert (msg[:content] || msg["content"]) =~ "error occurred"
    end
  end
end
