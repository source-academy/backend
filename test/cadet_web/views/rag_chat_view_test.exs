defmodule CadetWeb.RagChatViewTest do
  use CadetWeb.ConnCase, async: true

  alias CadetWeb.RagChatView

  test "renders conversation_init.json" do
    messages = [%{role: "assistant", content: "Hello!"}]

    result =
      RagChatView.render("conversation_init.json", %{
        conversation_id: 42,
        messages: messages,
        max_content_size: 1000
      })

    assert result == %{conversationId: 42, messages: messages, maxContentSize: 1000}
  end

  test "renders conversation.json" do
    result =
      RagChatView.render("conversation.json", %{
        conversation_id: 42,
        response: "Test response"
      })

    assert result == %{conversationId: 42, response: "Test response"}
  end
end
