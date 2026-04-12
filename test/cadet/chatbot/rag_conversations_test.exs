defmodule Cadet.Chatbot.RagConversationsTest do
  use Cadet.DataCase

  alias Cadet.Chatbot.RagConversations

  @rag_tag [%{"chat_type" => "rag"}]

  describe "get_or_create_conversation/1" do
    test "creates a new conversation when none exists" do
      user = insert(:user)
      assert {:ok, conversation} = RagConversations.get_or_create_conversation(user.id)
      assert conversation.user_id == user.id
      assert conversation.prepend_context == @rag_tag
      assert length(conversation.messages) == 1

      msg = hd(conversation.messages)
      assert msg[:role] || msg["role"] == "assistant"
    end

    test "returns existing conversation when one exists" do
      user = insert(:user)

      existing =
        insert(:conversation, user: user, prepend_context: @rag_tag)

      assert {:ok, conversation} = RagConversations.get_or_create_conversation(user.id)
      assert conversation.id == existing.id
    end
  end

  describe "get_conversation_for_user/1" do
    test "returns error when no RAG conversation exists" do
      user = insert(:user)
      assert {:error, {:not_found, _}} = RagConversations.get_conversation_for_user(user.id)
    end

    test "returns the RAG conversation for user" do
      user = insert(:user)

      conversation =
        insert(:conversation, user: user, prepend_context: @rag_tag)

      assert {:ok, found} = RagConversations.get_conversation_for_user(user.id)
      assert found.id == conversation.id
    end

    test "ignores non-RAG conversations" do
      user = insert(:user)
      # Insert a non-RAG conversation (empty prepend_context)
      insert(:conversation, user: user, prepend_context: [])

      assert {:error, {:not_found, _}} = RagConversations.get_conversation_for_user(user.id)
    end

    test "returns a RAG conversation when multiple exist" do
      user = insert(:user)

      insert(:conversation, user: user, prepend_context: @rag_tag)
      insert(:conversation, user: user, prepend_context: @rag_tag)

      assert {:ok, _found} = RagConversations.get_conversation_for_user(user.id)
    end
  end
end
